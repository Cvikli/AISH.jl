

@kwdef mutable struct SRWorkFlow <: Workflow
    persist::String
    conv_ctx::Session
    workspace_context::WorkspaceCTX
    julia_context::JuliaCTX
    # test_frame::TestFramework
    age_tracker::AgeTracker
    question_acc::QueryWithHistory
    q_history::QueryWithHistoryAndAIMsg=QueryWithHistoryAndAIMsg()
    agent::FluidAgent
    LLM_reflection::String
    version_control::Union{GitTracker,Nothing}
    no_confirm::Bool
end

function SRWorkFlow(project_paths; model="claude", no_confirm=false, detached_git_dev=true, verbose=true, tools=DEFAULT_TOOLS, kwargs...)
    persist           = kwargs[:logdir]
    conv_ctx          = initSession(sys_msg=SYSTEM_PROMPT(ChatSH; tools)) |> persist
    question_acc      = QueryWithHistory()
    project_paths     = length(project_paths) > 0 ? project_paths : [(init_virtual_workspace_path(persist, conv_ctx)).rel_path]
    workspace_context = init_workspace_context(project_paths; verbose)
    version_control   = detached_git_dev && false ? GitTracker!(workspace_context.workspace, persist, conv_ctx) : nothing
    julia_context     = init_julia_context()
    age_tracker       = AgeTracker(max_history=10, cut_to=4)
    agent            = FluidAgent(; tools, model)

    SRWorkFlow(conv_ctx; persist,
              question_acc,
              workspace_context,
              julia_context,
              age_tracker,
              agent,
              version_control,
              no_confirm)
end

function SRWorkFlow(conv_ctx::Session; persist::String,
                   question_acc, workspace_context, julia_context,
                   age_tracker, agent, version_control, no_confirm)
    LLM_reflection = ""
  append_ctx_descriptors(conv_ctx,
                          SHELL_run_results,
                          workspace_format_description(workspace_context.workspace),
                          julia_format_description(),
                          # test_format_description(test_frame),
                          )
    SRWorkFlow(persist, conv_ctx, workspace_context, julia_context, age_tracker,
              question_acc, QueryWithHistoryAndAIMsg(), agent, LLM_reflection,
              version_control, no_confirm)
end

function (m::SRWorkFlow)(user_question)
  occursin("MERGE", user_question) && return :MERGE

  # local ctx_test
  # cd(m.workspace_context.workspace.root_path) do
  #   ctx_test       = run_tests(m.test_frame) |> test_ctx_2_string
  # end
  # user_question    = add_tests(user_question, m.test_frame)
    ctx_shell, ctx_shell_cut = get_tool_results(m.agent)
  m.LLM_reflection = user_question

  while !isempty(m.LLM_reflection)
    user_question  = m.LLM_reflection

        ctx_question = format_history_query(m.question_acc(user_question))
    ctx_codebase   = process_workspace_context(m.workspace_context, ctx_question; m.age_tracker)
  # ctx_jl_pkg     = process_julia_context(m.julia_context, ctx_question; enabled=true, m.age_tracker)

    query = context_combiner!(
      user_question,
      ctx_shell,
      # ctx_test,
      (ctx_codebase),
      # (ctx_jl_pkg),
    )

    m.conv_ctx(create_user_message(query))
    m.persist(m.conv_ctx) # Persist after user message


    cache = get_cache_setting(m.age_tracker, m.conv_ctx)
    response = work(m.agent, m.conv_ctx; cache, m.no_confirm,
        tool_kwargs=Dict("root_path" => m.workspace_context.workspace.root_path),
        on_error=(error) -> add_error_message!(m.conv_ctx, "ERROR: $error")
    )
    m.conv_ctx(create_AI_message(response.content))
    ctx_shell, _ = get_tool_results(m.agent)
    !isnothing(m.version_control) && commit_changes(m.version_control, context_combiner!(user_question, ctx_shell, last_msg(m.conv_ctx)))
    LLM_answer, decision = LLM_reflect(ctx_question, ctx_shell, last_msg(m.conv_ctx))
    m.LLM_reflection = LLM_reflect_is_continue(decision) ? LLM_answer : ""

    cut_old_conversation_history!(m.age_tracker, m.conv_ctx, m.julia_context, m.workspace_context)
  end
  return :FINISHED
end
