
mutable struct SRWorkFlow{WORKSPACE,JULIA_CTX}
	persist::PersistableState
	conv_ctx::ConversationX
	workspace_context::WORKSPACE
	test_frame::TestFramework
	julia_context::JULIA_CTX
	age_tracker::AgeTracker
	question_acc::QuestionCTX
	extractor::CodeBlockExtractor
	LLM_reflection::String
	version_control::GitTracker
	no_confirm::Bool
end

SRWorkFlow(;user_question, resume, project_paths, logdir, show_tokens, silent, no_confirm,  test_cases, test_filepath) = begin
  persist           = PersistableState(logdir)
  conv_ctx          = init_conversation_context(SYSTEM_PROMPT(ChatSH)) |> persist
	# init_commit_msg = LLM_job_to_do(user_question)

  # workspace_context = init_workspace_context(project_paths, virtual_ws=virtual_workspace)
  # test_frame        = init_testframework(test_cases, folder_path=virtual_workspace.rel_path)
  project_paths     = length(project_paths) > 0 ? project_paths : [(init_virtual_workspace_path(conv_ctx) |> persist).rel_path]
  workspace_context = init_workspace_context(project_paths)
  test_frame        = init_testframework(test_cases, folder_path=project_paths[1])
  julia_context     = init_julia_context()
  version_control   = GitTracker!(workspace_context.workspace, persist, conv_ctx, user_question)
  
  age_tracker       = AgeTracker(max_history=14, cut_to=6)
  question_acc      = QuestionCTX()
  extractor         = CodeBlockExtractor()
  LLM_reflection    = ""

  append_ctx_descriptors(conv_ctx, 
                          shell_format_description(), 
                          workspace_format_description(), 
                          julia_format_description(), 
                          test_format_description(test_frame))
  
	SRWorkFlow(persist, conv_ctx, workspace_context, test_frame, julia_context, age_tracker, question_acc, extractor, LLM_reflection, version_control, no_confirm)
end


(m::SRWorkFlow)(user_question) = begin
  ctx_test         = run_tests(m.test_frame) |> test_ctx_2_string
  ctx_shell        = m.extractor             |> shell_ctx_2_string
  m.LLM_reflection = user_question
  while !isempty(m.LLM_reflection) 
    user_question  = m.LLM_reflection
    
    ctx_question   = user_question           |> m.question_acc
    ctx_codebase   = process_workspace_context(m.workspace_context, ctx_question; m.age_tracker)
    # ctx_jl_pkg     = process_julia_context(m.julia_context, ctx_question; m.age_tracker)
    @show "juliacontext is done!"
    query = context_combiner!(
      user_question, 
      ctx_shell, 
      ctx_test, 
      (ctx_codebase), 
      # (ctx_jl_pkg),
    )

    @show "??"
    
    m.conv_ctx(create_user_message(query))

    reset!(m.extractor)

    cache = get_cache_setting(m.age_tracker, m.conv_ctx)
    error = LLM_solve(m.conv_ctx, cache;
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, m.extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb)),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(m.conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> m.conv_ctx(ai_msg),
                      # on_done     = ()       -> (codeblock_runner(m.extractor, no_confirm=m.no_confirm);),
                      on_error    = (error)  -> add_error_message!(m.conv_ctx,"ERROR: $error"),
    )
    codeblock_runner(m.extractor, no_confirm=m.no_confirm)
    
    ctx_test       = run_tests(m.test_frame) |> test_ctx_2_string
    ctx_shell      = m.extractor             |> shell_ctx_2_string
    commit_changes(m.version_control, context_combiner!(user_question, ctx_shell, ctx_test, last_msg(m.conv_ctx)))
    LLM_answer     = LLM_reflect(ctx_question, ctx_shell, ctx_test, last_msg(m.conv_ctx))
    # println("-------LLM stuff")
    println(LLM_answer)
    m.LLM_reflection = is_continue(LLM_reflect_condition(LLM_answer)) ? LLM_answer : ""

    cut_old_history!(m.age_tracker, m.conv_ctx, m.julia_context, m.workspace_context, )

  end
end