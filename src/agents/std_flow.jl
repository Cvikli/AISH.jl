# Add at top with imports
using Memoize
using EasyContext: format_history_query, QueryWithHistoryAndAIMsg, FluidAgent

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
    planner::CodeCriticsArchitectContext=CodeCriticsArchitectContext(model="gem20f", enabled=false)
end
function STDFlow(project_paths; model="claude", no_confirm=false, verbose=true, tools=DEFAULT_SKILLS, kwargs...)

    m = STDFlow(;
        workspace_context=init_workspace_context(project_paths; model="dscode", verbose),
        julia_context=init_julia_context(excluded_packages=["XC", "QCODE"], model="gem20f"),
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

(flow::STDFlow)(user_question) = run(flow, user_question)
function run(flow::STDFlow, user_query, io::Union{IO, Nothing}=nothing)
    ctx_question = format_history_query(flow.question_acc(user_query))
    
    ctx_shell, ctx_shell_cut = get_tool_results(flow.agent)
    embedder_query = ctx_shell_cut * "\n\n" * ctx_question
    rerank_query = flow.q_history(user_query, flow.conv_ctx, ctx_shell_cut)

    write_event!(io, "context_shell", ctx_shell)

    ctx_jl_pkg   = @async_showerr process_julia_context(flow.julia_context, embedder_query; enabled=flow.use_julia, rerank_query, age_tracker=flow.age_tracker, io)
    ctx_codebase = @async_showerr process_workspace_context(flow.workspace_context, embedder_query; rerank_query, age_tracker=flow.age_tracker, io)
    context = context_combiner([fetch(ctx_jl_pkg), fetch(ctx_codebase), ctx_shell],)

    # Use transform directly if planner is enabled
    plan_context = transform(flow.planner, context, flow.conv_ctx)

    write_event!(io, "context_plan", plan_context)

    flow.conv_ctx(create_user_message(user_query, Dict("context" => context * plan_context)))

    cache = get_cache_setting(flow.age_tracker, flow.conv_ctx)
    response = work(flow.agent, flow.conv_ctx; cache, flow.no_confirm,
        tool_kwargs=Dict("root_path" => flow.workspace_context.workspace.root_path),
        on_error=(error) -> begin
            err_msg = "ERROR: $error"
            add_error_message!(flow.conv_ctx, err_msg)
            write_event!(io, "error", err_msg)
        end
    )

    write_event!(io, "ai_message", response.content)
    flow.conv_ctx(create_AI_message(response.content))

    log_instant_apply(flow.agent.extractor, ctx_question)
    cut_old_conversation_history!(flow.age_tracker, flow.conv_ctx, flow.julia_context, flow.workspace_context)
    return response
end

# Control functions
update_workspace!(flow::STDFlow, project_paths::Vector{<:AbstractString}) = begin
    flow.workspace_context = init_workspace_context(project_paths)
    flow.conv_ctx.system_message.content = SYSTEM_PROMPT(ChatSH; skills=flow.agent.tools, guide_strs=[workspace_format_description(flow.workspace_context.workspace), (flow.use_julia ? julia_format_guide : "")])
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
    new_flow = STDFlow(
        agent=flow.agent,
        project_paths=flow.workspace_context.workspace.project_paths,
        no_confirm=flow.no_confirm,
        use_planner=flow.planner.enabled,
        use_julia=flow.use_julia,
    )
    
    # Copy over the fields
    flow.workspace_context = new_flow.workspace_context
    flow.julia_context = new_flow.julia_context
    flow.conv_ctx = new_flow.conv_ctx
    flow.age_tracker = new_flow.age_tracker
    flow.question_acc = new_flow.question_acc
    flow.extractor = new_flow.extractor
    flow.planner = new_flow.planner
    
    return flow
end

