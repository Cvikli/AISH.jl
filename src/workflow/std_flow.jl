using EasyContext
using BoilerplateCvikli: @async_showerr

mutable struct STDFlow <: Workflow
    workspace_context::WorkspaceCTX
    julia_context::JuliaCTX
    conv_ctx::Session
    age_tracker::AgeTracker
    question_acc::QuestionCTX
    extractor::CodeBlockExtractor
    model::String
    no_confirm::Bool
    use_planner::Bool
    use_julia::Bool
    planner::ExecutionPlannerContext

    function STDFlow(;project_paths, model="claude-3-5-sonnet-20241022", no_confirm=false, verbose=true, use_planner=false, use_julia=false, kwargs...)
        m = new(
            init_workspace_context(project_paths; verbose),
            init_julia_context(),
            initSession(sys_msg=SYSTEM_PROMPT(ChatSH)),
            AgeTracker(max_history=10, cut_to=4),
            QuestionCTX(),
            CodeBlockExtractor(),
            model,
            no_confirm,
            use_planner,
            use_julia,
            ExecutionPlannerContext("oro1m")
        )
        append_ctx_descriptors(m.conv_ctx, SHELL_run_results, workspace_format_description(m.workspace_context.workspace), julia_format_description())
        m
    end
end

get_flags_str(flow::STDFlow) = string(flow.use_planner ? " [plan]" : "", flow.use_julia ? " [jl]" : "")

function (flow::STDFlow)(user_question)
    run(flow, user_question)
end

function run(flow::STDFlow, user_question)
    ctx_question = user_question |> flow.question_acc 
    ctx_shell    = flow.extractor |> shell_ctx_2_string
    allinfo = ctx_shell * "\n\n" * ctx_question 
    allinfo = length(allinfo) > 24000 ? (println("WARNING: All info is too long, cutting it to 24000(length(allinfo)) characters");allinfo[1:24000]) : allinfo
    ctx_jl_pks = flow.use_julia ? @async_showerr(process_julia_context(flow.julia_context, ctx_question; age_tracker=flow.age_tracker, extractor=flow.extractor)) : ""
    ctx_codebase = @async_showerr process_workspace_context(flow.workspace_context, allinfo; age_tracker=flow.age_tracker, extractor=flow.extractor)
    # ctx_jl_pkg   = @async_showerr process_julia_context(flow.julia_context, ctx_question; age_tracker=flow.age_tracker)

    @time "first" query = context_combiner!(
        user_question, 
        fetch(ctx_jl_pkg), 
        fetch(ctx_codebase), 
        ctx_shell, 
    )
    
    # Generate plan if planner is enabled, using the full context
    if flow.use_planner
        plan = flow.planner(flow.conv_ctx, query)
        println("EXECUTION_PLAN\n" * plan * "\n/EXECUTION_PLAN")
        query = query * "\n\n<EXECUTION_PLAN>\n" * plan * "\n</EXECUTION_PLAN>\n\n"
    end
    
    flow.conv_ctx(create_user_message(query))
    reset!(flow.extractor)

    cache = get_cache_setting(flow.age_tracker, flow.conv_ctx)
    @time "solve" error = LLM_solve(flow.conv_ctx, cache;
                      model       = flow.model,
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, flow.extractor, preprocess=(cb) -> LLM_conditonal_apply_changes(cb, ), root_path=flow.workspace_context.workspace.root_path),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(flow.conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> flow.conv_ctx(ai_msg),
                      on_done     = ()       -> @async_showerr(cd(()->codeblock_runner(flow.extractor; async=true), flow.workspace_context)),
                      on_error    = (error)  -> add_error_message!(flow.conv_ctx,"ERROR: $error"),
    )
    log_instant_apply(flow.extractor, ctx_question)
    cut_old_conversation_history!(flow.age_tracker, flow.conv_ctx, flow.julia_context, flow.workspace_context)
    return error
end

# Control functions
update_workspace!(flow::STDFlow, project_paths::Vector{<:AbstractString}) = begin
    flow.workspace_context = init_workspace_context(project_paths)
    reset_ctx_descriptors(flow.conv_ctx, SYSTEM_PROMPT(ChatSH))
    append_ctx_descriptors(flow.conv_ctx, 
        SHELL_run_results, 
        workspace_format_description(flow.workspace_context.workspace),
        julia_format_description()
    )
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
update_planner!(flow::STDFlow, planner::ExecutionPlannerContext) = (flow.planner = planner; flow)

function reset_flow!(flow::STDFlow)
    # Create a new instance with same settings
    new_flow = STDFlow(
        project_paths=flow.workspace_context.workspace.project_paths,
        model=flow.model,
        no_confirm=flow.no_confirm,
        use_planner=flow.use_planner,
        use_julia=flow.use_julia
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

