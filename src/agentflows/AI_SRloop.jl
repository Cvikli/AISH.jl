
mutable struct SRWorkFlow{WORKSPACE,JULIA_CTX}
	persist::PersistableState
	conv_ctx::ToSolve
	workspace_context::WORKSPACE
	test_frame::TestFramework
	julia_context::JULIA_CTX
	age_tracker::AgeTracker
	question_acc::QuestionCTX
	extractor::CodeBlockExtractor
	LLM_reflection::String
	no_confirm::Bool
end

init(::Type{SRWorkFlow}; resume, project_paths, logdir, show_tokens, silent, no_confirm, loop, test_cases, test_filepath) = begin
  persist           = Persistable(logdir)
  conv_ctx          = init_conversation_context(SYSTEM_PROMPT(ChatSH)) |> persist
  # virtual_workspace = init_virtual_workspace_context(conv_ctx)         |> persist
  # workspace_context = init_workspace_context(project_paths, virtual_ws=virtual_workspace)
  # test_frame        = init_testframework(test_cases, folder_path=virtual_workspace.rel_path)
  workspace_context = init_workspace_context(project_paths)
  test_frame        = init_testframework(test_cases, folder_path=project_paths[1])
  julia_context     = init_julia_context()
  
  age_tracker       = AgeTracker(max_history=14, cut_to=6)
  question_acc      = QuestionCTX()
  extractor         = CodeBlockExtractor()
  LLM_reflection    = ""
	SRWorkFlow(persist, conv_ctx, workspace_context, test_frame, julia_context, age_tracker, question_acc, extractor, LLM_reflection, no_confirm)
end


preparation(m::SRWorkFlow) = begin

  set_terminal_title("AISH $(m.workspace_context.workspace.root_path)")

  append_ctx_descriptors(m.conv_ctx, 
                          shell_format_description(), 
                          workspace_format_description(), 
                          # virtual_workspace_description(virtual_workspace), 
                          julia_format_description(), 
                          test_format_description(m.test_frame))
  
end

forward(user_question, m::SRWorkFlow; loop, silent) = begin
  ctx_test       = run_tests(m.test_frame) |> test_ctx_2_string
  ctx_shell      = m.extractor |> shell_ctx_2_string

  while loop || !isempty(user_question) || !isempty(m.LLM_reflection) 
    user_question = !isempty(m.LLM_reflection) ? m.LLM_reflection : 
                    !isempty(user_question)  ? user_question  : wait_user_question(user_question)
    !silent && println("Thinking...")  # Only print if not silent
    
    ctx_question   = user_question |> m.question_acc
    ctx_codebase   = @async_showerr process_workspace_context(m.workspace_context, ctx_question; m.age_tracker)
    ctx_jl_pkg     = @async_showerr process_julia_context(m.julia_context, ctx_question; m.age_tracker)

    query = context_combiner!(
      user_question, 
      ctx_shell, 
      ctx_test, 
      fetch(ctx_codebase), 
      fetch(ctx_jl_pkg),
    )

    m.conv_ctx(create_user_message(query))

    reset!(m.extractor)
    user_question = ""

    cache = get_cache_setting(m.age_tracker, m.conv_ctx)
    error = LLM_solve(m.conv_ctx, cache;
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, m.extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb)),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(m.conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> m.conv_ctx(ai_msg),
                      on_done     = ()       -> (codeblock_runner(m.extractor, no_confirm=m.no_confirm)),
                      on_error    = (error)  -> add_error_message!(m.conv_ctx,"ERROR: $error"),
    )

    # ctx_test       = run_tests(m.test_frame) |> test_ctx_2_string
    # @show "----------ctx_test"
    # println(ctx_test)
    # ctx_shell      = m.extractor |> shell_ctx_2_string
    LLM_answer     = LLM_reflect(ctx_question, ctx_shell, ctx_test, last_msg(m.conv_ctx))
    # println("-------LLM stuff")
    # println(LLM_answer)
    m.LLM_reflection = is_continue(LLM_reflect_condition(last_msg(m.conv_ctx))) ? LLM_answer : ""

    cut_old_history!(m.age_tracker, m.conv_ctx, m.julia_context, m.workspace_context, )

    silent && break
  end
end