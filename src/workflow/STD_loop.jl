using EasyContext
using BoilerplateCvikli: @async_showerr

struct AIModel
	workspace_context
	julia_context
    conv_ctx::ConversationX
    age_tracker::AgeTracker
	question_acc::QuestionCTX
	extractor::CodeBlockExtractor

    function AIModel(project_paths)
        m = new(
            init_workspace_context(project_paths),
            init_julia_context(),
            init_conversation_context(SYSTEM_PROMPT(ChatSH)),
            AgeTracker(max_history=10, cut_to=4),
            QuestionCTX(),
            CodeBlockExtractor(),
        )
        append_ctx_descriptors(m.conv_ctx, SHELL_run_results, workspace_format_description(m.workspace_context.workspace), julia_format_description())
        m
    end
end

function (model::AIModel)(user_question)
    ctx_question = user_question |> model.question_acc 
    ctx_shell    = model.extractor |> shell_ctx_2_string
    ctx_codebase = @async_showerr process_workspace_context(model.workspace_context, ctx_question; age_tracker=model.age_tracker)
    ctx_jl_pkg   = @async_showerr process_julia_context(model.julia_context, ctx_question; age_tracker=model.age_tracker)

    query = context_combiner!(
        user_question, 
        ctx_shell, 
        fetch(ctx_codebase), 
        fetch(ctx_jl_pkg),
    )

    model.conv_ctx(create_user_message(query))

    reset!(model.extractor)

    cache = get_cache_setting(model.age_tracker, model.conv_ctx)
    error = LLM_solve(model.conv_ctx, cache;
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, model.extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb, model.workspace_context.workspace)),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(model.conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> model.conv_ctx(ai_msg),
                      on_done     = ()       -> @async_showerr(cd(()->codeblock_runner(model.extractor), model.workspace_context)),
                      on_error    = (error)  -> add_error_message!(model.conv_ctx,"ERROR: $error"),
    )

    cut_old_history!(model.age_tracker, model.conv_ctx, model.julia_context, model.workspace_context)

    return error
end
