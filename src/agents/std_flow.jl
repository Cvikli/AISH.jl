# Add at top with imports
using Memoize
using EasyContext: format_history_query, QueryWithHistoryAndAIMsg, FluidAgent
using EasyContext: get_context!, get_tool_results_agent, transform
using EasyRAGStore: IndexLogger, log_index
using DingDingDing

@kwdef mutable struct STDFlow <: Workflow
    workspace_context::WorkspaceCTX
    julia_context::JuliaCTX
    conv_ctx::Session=Session()
    age_tracker::AgeTracker=AgeTracker(max_history=10, cut_to=4)
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
    WorkspaceToolGenerator(; workspace_context),
    JuliaSearchTool,
]

function STDFlow(project_paths; no_confirm=false, verbose=true, kwargs...)
    
    workspace_context = init_workspace_context(project_paths; 
        pipeline=EFFICIENT_PIPELINE(cache_prefix="workspace"), 
        verbose
    )
    tools = get_default_tools(workspace_context)
    create_sys_msg() = SYSTEM_PROMPT(ChatSH; guide_strs=[
        workspace_format_description_raw(workspace_context.workspace),
        # TODO handle (use_julia ? julia_format_guide : "")
    ]) 

    m = STDFlow(;
        workspace_context,
        julia_context=init_julia_context(
            excluded_packages=["XC", "QCODE"],
            pipeline=HIGH_ACCURACY_PIPELINE(cache_prefix="juliapkgs")
        ),
        agent=create_FluidAgent("claude"; create_sys_msg, tools),
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

    ctx_shell = get_tool_results_agent(flow.agent, filter_tools=[ShellBlockTool])
    embedder_query = """
    $ctx_shell\n
    $query_history\n
    $user_query
    """
    rerank_query = get_context!(flow.q_history, user_query, flow.conv_ctx, ctx_shell)

    # jl_chunks = search_julia_pkgs(embedder_query; enabled=flow.use_julia, rerank_query)
    # ws_chunks = search_workspace(embedder_query; rerank_query)
    # register_chunks!(flow.chat, jl_chunks, format_prefix="# julia functions:")
    # register_chunks!(flow.chat, ws_chunks, format_prefix="# workspace files:", need_updates=true)

    filechunks_str, file_chunks = process_workspace_context(flow.workspace_context, embedder_query; rerank_query, age_tracker=flow.age_tracker, io)
    @show length(filechunks_str)
    context = context_combiner([filechunks_str, ctx_shell])
    
    log_index(flow.ws_index_logger, file_chunks, rerank_query, answer=filechunks_str)
    
    plan_context = transform(flow.planner, context, flow.conv_ctx; io)

    # push_message!(flow.conv_ctx, ctx_shell_cut * plan_context * user_query)

    push_message!(flow.conv_ctx, create_user_message(user_query, Dict("context" => context * plan_context)))

    cache = get_cache_setting(flow.age_tracker, flow.conv_ctx)
    response = work(flow.agent, flow.conv_ctx; cache, flow.no_confirm,
        tool_kwargs=Dict("root_path" => flow.workspace_context.workspace.root_path),
        on_error=(error) -> begin
            err_msg = "ERROR: $error\n$(sprint(showerror, error, catch_backtrace()))"
            add_error_message!(flow.conv_ctx, err_msg)
            println(io, err_msg)
        end,
        io,
        thinking=flow.thinking
    )

    log_instant_apply(flow.agent.extractor, query_history * "\n\n# User query:\n" * user_query)
    cut_old_conversation_history!(flow.age_tracker, flow.conv_ctx, flow.julia_context, flow.workspace_context)
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
    create_sys_msg() = SYSTEM_PROMPT(ChatSH; guide_strs=[
        workspace_format_description_raw(workspace_context.workspace),
    ])
    flow.agent = create_FluidAgent("claude"; create_sys_msg, tools)
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
    cut_old_conversation_history!(flow.age_tracker, flow.conv_ctx, flow.julia_context, flow.workspace_context)
    flow
end

# Simplified planner control functions since planner is always initialized
toggle_planner!(flow::STDFlow) = (flow.planner.enabled = !flow.planner.enabled; flow)

function reset_flow!(flow::STDFlow)
    # Create a new instance with same settings
    new_flow = STDFlow(flow.workspace_context.workspace.project_paths;
        no_confirm=flow.no_confirm,
        use_planner=flow.planner.enabled,
    )

    # Preserve thinking setting
    new_flow.thinking = flow.thinking

    return new_flow
end

