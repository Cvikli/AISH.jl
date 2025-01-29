# Add at top with imports
using Memoize
using EasyContext: format_history_query, QueryWithHistoryAndAIMsg, FluidAgent
using EasyRAGStore: IndexLogger, log_index

@kwdef mutable struct STDFlow <: Workflow
    workspace_context::WorkspaceCTX
    julia_context::JuliaCTX
    conv_ctx::Session=initSession()
    age_tracker::AgeTracker=AgeTracker(max_history=10, cut_to=4)
    question_acc::QueryWithHistory=QueryWithHistory()
    q_history::QueryWithHistoryAndAIMsg=QueryWithHistoryAndAIMsg()
    agent::FluidAgent
    no_confirm::Bool=true
    use_julia::Bool=false
    planner::AbstractPlanner=ExecutionPlannerContext(model="dsreason", enabled=false)
    ws_index_logger::IndexLogger=IndexLogger("workspace_chunks")
    jl_index_logger::IndexLogger=IndexLogger("julia_src_chunks")
end

function STDFlow(project_paths; model="claude", no_confirm=false, verbose=true, tools=DEFAULT_TOOLS, kwargs...)

    m = STDFlow(;
        workspace_context=init_workspace_context(project_paths; model=["dscode", "gem20f", "gem15f", "gpt4om"], verbose, top_n=10),
        julia_context=init_julia_context(excluded_packages=["XC", "QCODE"], model=["dscode", "gem20f", "gem15f", "gpt4om"]),
        agent=FluidAgent(; tools, model),
        no_confirm,
    )
    m.conv_ctx.system_message.content = SYSTEM_PROMPT(ChatSH; tools,
    guide_strs=[
        workspace_format_description_raw(m.workspace_context.workspace),
        ]) # TODO handle (use_julia ? julia_format_guide : "")
    # print_project_tree(m.workspace_context.workspace, summary_callback=LLM_summary)
    # println(workspace_format_description(m.workspace_context.workspace))
    m
end

get_flags_str(flow::STDFlow) = begin
    flags = String[]
    flow.planner.enabled && push!(flags, "plan" * (occursin("oro", flow.planner.model) ? "\$" : ""))
    flow.use_julia && push!(flags, "jl")
    isempty(flags) ? "" : " [" * join(flags, " ") * "]"
end

(flow::STDFlow)(user_question, io::IO=stdout) = run(flow, user_question, io)
function run(flow::STDFlow, user_query, io::IO=stdout)
    ctx_question = format_history_query(flow.question_acc(user_query))

    ctx_shell, ctx_shell_cut = get_tool_results(flow.agent, filter_tools=[ShellBlockTool])
    embedder_query = ctx_shell_cut * "\n\n" * ctx_question
    rerank_query = flow.q_history(user_query, flow.conv_ctx, ctx_shell_cut)

    jl_task = @async_showerr process_julia_context(flow.julia_context, embedder_query; enabled=flow.use_julia, rerank_query, age_tracker=flow.age_tracker, io)
    ws_task = @async_showerr process_workspace_context(flow.workspace_context, embedder_query; rerank_query, age_tracker=flow.age_tracker, io)
    src_chunks_reranked, src_chunks = fetch(jl_task)
    val = fetch(ws_task)
    file_chunks_reranked, file_chunks = val
    context = context_combiner([src_chunks_reranked, file_chunks_reranked, ctx_shell],)

    log_index(flow.ws_index_logger, file_chunks, rerank_query, answer=src_chunks_reranked)
    log_index(flow.jl_index_logger, src_chunks, rerank_query, answer=src_chunks_reranked)

    plan_context = transform(flow.planner, context, flow.conv_ctx; io)


    flow.conv_ctx(create_user_message(user_query, Dict("context" => context * plan_context)))

    cache = get_cache_setting(flow.age_tracker, flow.conv_ctx)
    response = work(flow.agent, flow.conv_ctx; cache, flow.no_confirm,
        tool_kwargs=Dict("root_path" => flow.workspace_context.workspace.root_path),
        on_error=(error) -> begin
            err_msg = "ERROR: $error"
            add_error_message!(flow.conv_ctx, err_msg)
            println(io, err_msg)
        end,
        io
    )

    flow.conv_ctx(create_AI_message(response.content))

    log_instant_apply(flow.agent.extractor, ctx_question)
    cut_old_conversation_history!(flow.age_tracker, flow.conv_ctx, flow.julia_context, flow.workspace_context)
    return response
end

# Control functions
update_workspace!(flow::STDFlow, project_paths::Vector{<:AbstractString}) = begin
    flow.workspace_context = init_workspace_context(project_paths)
    flow.conv_ctx.system_message.content = SYSTEM_PROMPT(ChatSH; tools=flow.agent.tools, guide_strs=[workspace_format_description_raw(flow.workspace_context.workspace), (flow.use_julia ? julia_format_guide : "")])
    return flow
end

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


    return new_flow
end

