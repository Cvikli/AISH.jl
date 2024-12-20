

mutable struct SRWorkFlow <: Workflow
    persist::PersistableState
    conv_ctx::Session 
    workspace_context::WorkspaceCTX
    julia_context::JuliaCTX
    # test_frame::TestFramework
    age_tracker::AgeTracker
    question_acc::QuestionCTX
    extractor::StreamParser
    LLM_reflection::String
    version_control::Union{GitTracker,Nothing}
    no_confirm::Bool
end

SRWorkFlow(;project_paths, logdir, show_tokens, no_confirm, detached_git_dev=true, verbose=true, skills=DEFAULT_SKILLS, kwargs...) = begin
  persist           = PersistableState(logdir)
  conv_ctx          = initSession(sys_msg=SYSTEM_PROMPT(ChatSH; skills)) |> persist  
  question_acc      = QuestionCTX()
  project_paths     = length(project_paths) > 0 ? project_paths : [(init_virtual_workspace_path(persist, conv_ctx)).rel_path]
  workspace_context = init_workspace_context(project_paths; show_tokens, verbose)
  version_control   = detached_git_dev && false ? GitTracker!(workspace_context.workspace, persist, conv_ctx) : nothing
  julia_context     = init_julia_context()

  age_tracker       = AgeTracker(max_history=10, cut_to=4)

  SRWorkFlow(conv_ctx;persist, question_acc, 
              workspace_context, julia_context,
              age_tracker,
              version_control,
              no_confirm)
end

SRWorkFlow(conv_ctx::Session; persist::PersistableState, question_acc,  
            workspace_context, julia_context,
            age_tracker,
            version_control,
            no_confirm, kwargs...) = begin
  
  extractor         = StreamParser()
  LLM_reflection    = ""
  
  append_ctx_descriptors(conv_ctx, 
                          SHELL_run_results, 
                          workspace_format_description(workspace_context.workspace), 
                          julia_format_description(), 
                          # test_format_description(test_frame),
                          )
  
	SRWorkFlow(persist, conv_ctx, workspace_context, 
              # test_frame, 
              julia_context, age_tracker, question_acc, extractor, LLM_reflection, version_control, no_confirm)
end


(m::SRWorkFlow)(user_question) = begin
  occursin("MERGE", user_question) && return :MERGE

  # local ctx_test
  # cd(m.workspace_context.workspace.root_path) do
  #   ctx_test       = run_tests(m.test_frame) |> test_ctx_2_string
  # end
  # user_question    = add_tests(user_question, m.test_frame)
  ctx_shell        = m.extractor             |> shell_ctx_2_string
  m.LLM_reflection = user_question
  
  while !isempty(m.LLM_reflection) 
    user_question  = m.LLM_reflection
    
    ctx_question   = user_question           |> m.question_acc
    ctx_codebase   = process_workspace_context(m.workspace_context, ctx_question; m.age_tracker)
  # ctx_jl_pkg     = process_julia_context(m.julia_context, ctx_question; m.age_tracker)

    query = context_combiner!(
      user_question, 
      ctx_shell, 
      # ctx_test, 
      (ctx_codebase),  
      # (ctx_jl_pkg),
    )

    m.conv_ctx(create_user_message(query))
    m.persist(m.conv_ctx) # Persist after user message

    reset!(m.extractor)

    cache = get_cache_setting(m.age_tracker, m.conv_ctx)
    error = LLM_solve(m.conv_ctx, cache;
                      stop_sequences = m.stop_sequences,
                      on_text     = (text)   -> extract_commands(text, m.extractor, root_path=m.workspace_context.workspace.root_path),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(m.conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> m.conv_ctx(ai_msg) |> m.persist,
                      # on_done     = ()       -> (codeblock_runner(m.extractor, no_confirm=m.no_confirm);),
                      on_error    = (error)  -> add_error_message!(m.conv_ctx,"ERROR: $error"),
    )
    cd(m.workspace_context) do
      run_stream_parser(m.extractor, no_confirm=m.no_confirm)
      # ctx_test       = run_tests(m.test_frame) |> test_ctx_2_string
    end
    ctx_shell        = m.extractor             |> shell_ctx_2_string
    !isnothing(m.version_control) && commit_changes(m.version_control, context_combiner!(user_question, ctx_shell, last_msg(m.conv_ctx)))
    LLM_answer, decision = LLM_reflect(ctx_question, ctx_shell, last_msg(m.conv_ctx))
    m.LLM_reflection = LLM_reflect_is_continue(decision) ? LLM_answer : ""

    cut_old_conversation_history!(m.age_tracker, m.conv_ctx, m.julia_context, m.workspace_context)
  end
  return :FINISHED
end
