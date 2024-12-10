# Add at top with imports
using Memoize
using Markdown  # Add at top with imports
using EasyContext: flush!

mutable struct STDFlow <: Workflow
    workspace_context::WorkspaceCTX
    julia_context::JuliaCTX
    conv_ctx::Session
    age_tracker::AgeTracker
    question_acc::QuestionCTX
    extractor::StreamParser
    model::String
    skills::Vector{Skill}  # Store skills instead of stop_sequences
    no_confirm::Bool
    use_planner::Bool
    use_julia::Bool
    planner::ExecutionPlannerContext

    function STDFlow(;project_paths, model="claude-3-5-sonnet-20241022", no_confirm=false, verbose=true, use_planner=false,
        use_julia=false, skills=DEFAULT_SKILLS, kwargs...)
        m = new(
            init_workspace_context(project_paths; verbose),
            init_julia_context(),
            initSession(),
            AgeTracker(max_history=10, cut_to=4),
            QuestionCTX(),
            StreamParser(),
            model,
            skills,  # Store skills directly
            no_confirm,
            use_planner,
            use_julia,
            ExecutionPlannerContext(model="oro1m")
        )
        m.conv_ctx.system_message.content = SYSTEM_PROMPT(ChatSH; skills, 
        guide_strs=[
            workspace_format_description(m.workspace_context.workspace), 
            (use_julia ? julia_format_guide : "")])
        # print_project_tree(m.workspace_context.workspace, summary_callback=LLM_summary)
        # println(workspace_format_description(m.workspace_context.workspace))
        m
    end
end

# Add memoized getter for stop_sequences
@memoize function get_stop_sequences(flow::STDFlow)
    unique([s.stop_sequence for s in flow.skills if !isempty(s.stop_sequence)])
end

get_flags_str(flow::STDFlow) = begin
    flags = String[]
    flow.use_planner && push!(flags, "plan" * (occursin("oro", flow.planner.model) ? "\$" : ""))
    flow.use_julia && push!(flags, "jl")
    isempty(flags) ? "" : " [" * join(flags, " ") * "]"
end

(flow::STDFlow)(user_question) = run(flow, user_question)
function run(flow::STDFlow, user_question)
    ctx_question = user_question |> flow.question_acc
    ctx_shell    = flow.extractor |> shell_ctx_2_string
    length(ctx_shell) > (20000-length(ctx_question)) && println("WARNING: All info is too long, cutting it to 24000(length(allinfo)) characters")
    allinfo = ctx_shell[1:min(20000-length(ctx_question), end)] * "\n\n" * ctx_question
    ctx_jl_pkg = flow.use_julia ? @async_showerr(process_julia_context(flow.julia_context, ctx_question; age_tracker=flow.age_tracker)) : ""
    ctx_codebase = @async_showerr process_workspace_context(flow.workspace_context, allinfo; age_tracker=flow.age_tracker)

    query = context_combiner!(
        user_question,
        fetch(ctx_jl_pkg),
        fetch(ctx_codebase),
        ctx_shell,
    )

    # Generate plan if planner is enabled, using the full context
    if flow.use_planner
        plan = flow.planner(flow.conv_ctx, query, history_count=3)
        display(Markdown.parse("# EXECUTION_PLAN\n" * plan))
        query = query * "\n\n<EXECUTION_PLAN>\n" * plan * "\n</EXECUTION_PLAN>\n\n"
    end

    flow.conv_ctx(create_user_message(query))

    while true
        toolcall = false    
        cache = get_cache_setting(flow.age_tracker, flow.conv_ctx)
        aimessage, cb = LLM_solve(flow.conv_ctx, cache;
                        flow.extractor,
                        root_path      = flow.workspace_context.workspace.root_path,
                        stop_sequences = get_stop_sequences(flow),
                        model          = flow.model,
                        on_error       = (error)  -> add_error_message!(flow.conv_ctx,"ERROR: $error"),
        )
        
        run_stream_parser(flow.extractor, root_path=flow.workspace_context.workspace.root_path, async=true)
        # postcall saves.
        (!toolcall || isempty(flow.extractor.command_tasks)) && break

        result = execute_last_command(flow.extractor)
        isnothing(result) && continue
        print_tool_result(result)
        flow.conv_ctx(create_user_message(truncate_output(result)))
    end
    log_instant_apply(flow.extractor, ctx_question)
    cut_old_conversation_history!(flow.age_tracker, flow.conv_ctx, flow.julia_context, flow.workspace_context)
    return error
end

# Control functions
update_workspace!(flow::STDFlow, project_paths::Vector{<:AbstractString}) = begin
    flow.workspace_context = init_workspace_context(project_paths)
    flow.conv_ctx.system_message.content = SYSTEM_PROMPT(ChatSH; skills=flow.skills, guide_strs=[workspace_format_description(flow.workspace_context.workspace), (flow.use_julia ? julia_format_guide : "")])
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
toggle_planner!(flow::STDFlow) = (flow.use_planner = !flow.use_planner; flow)

function reset_flow!(flow::STDFlow)
    # Create a new instance with same settings
    new_flow = STDFlow(
        project_paths=flow.workspace_context.workspace.project_paths,
        model=flow.model,
        no_confirm=flow.no_confirm,
        use_planner=flow.use_planner,
        use_julia=flow.use_julia,
        skills=flow.skills  # Pass the existing skills
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

