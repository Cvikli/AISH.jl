# Add at top with imports
using Memoize
using EasyContext: format_history_query, QueryWithHistoryAndAIMsg, FluidAgent
using EasyContext: get_context!, transform, NativeExtractor
using EasyContext: SourceTracker, AbstractCutter, AgeBasedCutter, maybe_cut!, get_cache_setting, register_changes!, update_age!
using EasyRAGStore: IndexLogger, log_index
using DingDingDing
using OpenContentBroker

# Tool output text from the trailing run of :tool messages left by the previous turn.
last_tool_results(conv_ctx::Session) = begin
    msgs = conv_ctx.messages
    i = length(msgs)
    while i > 0 && msgs[i].role === :tool
        i -= 1
    end
    join((m.content for m in @view msgs[i+1:end]), "\n")
end

@kwdef mutable struct STDFlow <: Workflow
    workspace_context::WorkspaceCTX
    julia_context::JuliaCTX
    conv_ctx::Session=Session()
    source_tracker::SourceTracker=SourceTracker()
    cutter::AbstractCutter=AgeBasedCutter(max_messages=10, keep_messages=4)
    question_acc::QueryWithHistory=QueryWithHistory()
    q_history::QueryWithHistoryAndAIMsg=QueryWithHistoryAndAIMsg()
    agent::FluidAgent
    no_confirm::Bool=true
    use_julia::Bool=false
    planner::AbstractPlanner=ExecutionPlannerContext(model="dsreason", enabled=false)
    ws_index_logger::IndexLogger=IndexLogger("workspace_chunks")
    jl_index_logger::IndexLogger=IndexLogger("julia_src_chunks")
    thinking::Union{Nothing,Int}=nothing  # Add thinking parameter
end

get_default_tools(workspace_context::WorkspaceCTX) = [
    CatFileTool, 
    CreateFileTool, 
    ModifyFileTool,
    ShellBlockTool,
    WorkspaceToolGenerator{FileChunk}(; workspace_context),
    JuliaSearchTool,
    WebContentTool,
    SearchGitingestTool,
    # GoogleSearchTool,
    GoogleRAGTool,
    GmailSenderTool,
    GmailSearchTool,
]

function STDFlow(project_paths; no_confirm=false, verbose=true, kwargs...)
    
    workspace_context = init_workspace_context(project_paths; 
        pipeline=EFFICIENT_PIPELINE(cache_prefix="workspace", model=["gem25f", "gem20f"]), 
        verbose
    )
    tools = get_default_tools(workspace_context)
    sys_msg = SYSTEM_PROMPT(ChatSH; ) 
    # tools = Dict(WORKSPACE_SEARCH_TAG => args -> WorkspaceSearchTool(args..., workspace_context, root_path),
    #     CatFileTool => args -> CatFileTool(RemoteEdgePath),
    # )

    m = STDFlow(;
        workspace_context,
        julia_context=init_julia_context(
            excluded_packages=["XC", "QCODE"],
            pipeline=HIGH_ACCURACY_PIPELINE(cache_prefix="juliapkgs")
        ),
        agent=create_FluidAgent("claude"; sys_msg, tools, extractor_type=NativeExtractor),
        no_confirm,
    )
    # m.conv_ctx.system_message.content =  # TODO handle (use_julia ? julia_format_guide : "")
    # print_project_tree(m.workspace_context.workspace, summary_callback=LLM_summary)
    # println(workspace_format_description(m.workspace_context.workspace))
    m
end

get_flags_str(flow::STDFlow) = begin
    flags = String[]
    flow.planner.enabled && push!(flags, "plan" * (occursin("oro", flow.planner.model) ? "\$" : ""))
    flow.use_julia && push!(flags, "jl")
    !isnothing(flow.thinking) && push!(flags, "think$(flow.thinking ÷ 1000)k")
    isempty(flags) ? "" : " [" * join(flags, " ") * "]"
end

function run(flow::STDFlow, user_query, io::IO=stdout)
    query_history = get_context!(flow.question_acc, user_query)

    ctx_shell = last_tool_results(flow.conv_ctx)
    embedder_query = """$ctx_shell
    
    $query_history
    
    $user_query"""

    rerank_query = get_context!(flow.q_history, user_query, flow.conv_ctx, ctx_shell)

    # jl_chunks = search_julia_pkgs(embedder_query; enabled=flow.use_julia, rerank_query)
    # ws_chunks = search_workspace(embedder_query; rerank_query)
    # register_chunks!(flow.chat, jl_chunks, format_prefix="# julia functions:")
    # register_chunks!(flow.chat, ws_chunks, format_prefix="# workspace files:", need_updates=true)

    filechunks_str, file_chunks = process_workspace_context(flow.workspace_context, embedder_query; rerank_query, source_tracker=flow.source_tracker, io)
    context = context_combiner([filechunks_str, ctx_shell])
    
    log_index(flow.ws_index_logger, file_chunks, rerank_query, answer=filechunks_str)
    
    plan_context = transform(flow.planner, context, flow.conv_ctx; io)

    # push_message!(flow.conv_ctx, ctx_shell_cut * plan_context * user_query)

    push_message!(flow.conv_ctx, create_user_message(user_query, Dict("context" => context * plan_context)))

    response = try
        work(flow.agent, flow.conv_ctx;
            cache=get_cache_setting(flow.cutter, flow.conv_ctx, flow.source_tracker),
            cutter=flow.cutter,
            source_tracker=flow.source_tracker,
            tool_kwargs=Dict("root_path" => flow.workspace_context.workspace.root_path, :no_confirm => flow.no_confirm),
            on_error=(error) -> begin
                err_msg = "ERROR: $error\n$(sprint(showerror, error, catch_backtrace()))"
                add_error_message!(flow.conv_ctx, err_msg)
                println(io, err_msg)
            end,
            io,
            thinking=flow.thinking
        )
    catch e
        e isa InterruptException && rethrow(e)
        # display(catch_backtrace())
        @error "Error in fluidagent work" exception=(e, catch_backtrace())
        on_error(e)

        content = "Error: $(sprint(showerror, e))\n\nStacktrace:\n$(join(string.(stacktrace(catch_backtrace())), "\n"))"
        push_message!(flow.conv_ctx, create_AI_message(content))
        return (; 
            content,
            results = OrderedDict{UUID,String}(),
            run_info = nothing,
        )
    end

    update_age!(flow.source_tracker)
    maybe_cut!(flow.cutter, flow.conv_ctx, flow.source_tracker, flow.workspace_context)

    @static if !Sys.isapple()
        DingDingDing.play(DingDingDing.rand_sound_file(DingDingDing.ding_files))
    end
    return response
end

# Control functions
update_workspace!(flow::STDFlow, project_paths::Vector{<:AbstractString}) = begin
    # Create a new pipeline with the same configuration as the current one
    current_reranker = flow.workspace_context.rag_pipeline.reranker
    pipeline = EFFICIENT_PIPELINE(
        model=current_reranker.model,
        top_n=current_reranker.top_n,
        rerank_prompt=current_reranker.rerank_prompt
    )
    
    workspace_context = init_workspace_context(project_paths; pipeline)
    tools = get_default_tools(workspace_context)
    sys_msg = SYSTEM_PROMPT(ChatSH)
    
    flow.agent = create_FluidAgent("claude"; sys_msg, tools, extractor_type=NativeExtractor)
    flow.workspace_context = workspace_context
    return flow
end

# Add a simple update_model! function
update_model!(flow::STDFlow, model_name::AbstractString) = 
    isempty(model_name) ? false : (flow.agent.model = model_name; true)

function normalize_conversation!(flow::STDFlow)
    if !isempty(flow.conv_ctx.messages) && flow.conv_ctx.messages[end].role == :user
        # Add a closure message instead of removing the user message
        flow.conv_ctx(create_AI_message("Operation was interrupted. The answer was cancelled."))
    end
    maybe_cut!(flow.cutter, flow.conv_ctx, flow.source_tracker, flow.workspace_context)
    flow
end

# Simplified planner control functions since planner is always initialized
toggle_planner!(flow::STDFlow) = (flow.planner.enabled = !flow.planner.enabled; flow)

function reset_flow!(flow::STDFlow)
    # Create a new instance with same settings
    new_flow = STDFlow(flow.workspace_context.workspace.project_paths;
        no_confirm=flow.no_confirm,
        use_planner=flow.planner.enabled,
        thinking=flow.thinking
    )

    return new_flow
end

