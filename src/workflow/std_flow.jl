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

    function STDFlow(;project_paths, model="claude-3-5-sonnet-20241022", no_confirm=false, kwargs...)
        m = new(
            init_workspace_context(project_paths),
            init_julia_context(),
            initSession(sys_msg=SYSTEM_PROMPT(ChatSH)),
            AgeTracker(max_history=10, cut_to=4),
            QuestionCTX(),
            CodeBlockExtractor(),
            model,
            no_confirm,
        )
        append_ctx_descriptors(m.conv_ctx, SHELL_run_results, workspace_format_description(m.workspace_context.workspace), julia_format_description())
        m
    end
end

function (flow::STDFlow)(user_question)
    run(flow, user_question)
end
function run(flow::STDFlow, user_question)
    ctx_question = user_question |> flow.question_acc 
    ctx_shell    = flow.extractor |> shell_ctx_2_string
    ctx_codebase = @async_showerr process_workspace_context(flow.workspace_context, ctx_question; age_tracker=flow.age_tracker)
    # ctx_jl_pkg   = @async_showerr process_julia_context(flow.julia_context, ctx_question; age_tracker=flow.age_tracker)

    @time "first" query = context_combiner!(
        user_question, 
        # fetch(ctx_jl_pkg), 
        fetch(ctx_codebase), 
        ctx_shell, 
    )
    
    flow.conv_ctx(create_user_message(query))
    reset!(flow.extractor)

    cache = get_cache_setting(flow.age_tracker, flow.conv_ctx)
    @time "solve" error = LLM_solve(flow.conv_ctx, cache;
                      model       = flow.model,
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, flow.extractor, preprocess=(cb) -> LLM_conditonal_apply_changes(cb, ), root_path=flow.workspace_context.workspace.root_path),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(flow.conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> flow.conv_ctx(ai_msg),
                      on_done     = ()       -> @async_showerr(cd(()->codeblock_runner(flow.extractor), flow.workspace_context)),
                      on_error    = (error)  -> add_error_message!(flow.conv_ctx,"ERROR: $error"),
    )
    log_instant_apply(flow.extractor, ctx_question)
    cut_old_conversation_history!(flow.age_tracker, flow.conv_ctx, flow.julia_context, flow.workspace_context)
    return error
end
update_model!(flow::STDFlow, new_model::AbstractString) = (flow.model = new_model; flow)
toggle_confirm!(flow::STDFlow) = (flow.no_confirm = !flow.no_confirm; flow)

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

