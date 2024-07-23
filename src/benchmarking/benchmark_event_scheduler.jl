using AISH: initialize_ai_state
using JuliaLLMLeaderboard
using RelevanceStacktrace
using PromptingTools
using TOML

function benchmark_event_scheduler()
  # Load definition
  fn_definition = joinpath(dirname(dirname(pathof(JuliaLLMLeaderboard))),
      "code_generation",
      "utility_functions",
      "event_scheduler",
      "definition.toml")
  println("Definition file: $fn_definition")
  definition = TOML.parsefile(fn_definition)["code_generation"]  

  # Initialize AI state
  ai_state = initialize_ai_state()  

  # Prepare conversation
  full_msg = definition["prompt"]
  push!(ai_state.conversation, PromptingTools.UserMessage("<USER>\n$(full_msg)\n</USER>"))  

  # Benchmark the AI generation
  conversation = aigenerate($ai_state.conversation, model=$ai_state.model, return_all=true)
  extract_julia_code(conversation[end].content)  

  # Print benchmark results
  println("Benchmark results:")  

  # Evaluate 1SHOT
  conversation_mod = deepcopy(conversation)
  conversation_mod[end] = PromptingTools.AIMessage(
      extract_julia_code(conversation_mod[end].content),
      conversation_mod[end].status,
      conversation_mod[end].tokens,
      conversation_mod[end].elapsed,
      conversation_mod[end].cost,
      conversation_mod[end].log_prob,
      conversation_mod[end].finish_reason,
      conversation_mod[end].run_id,
      conversation_mod[end].sample_id,
      conversation_mod[end]._type
  )  

  eval_result = evaluate_1shot(
      conversation=conversation_mod,
      fn_definition=fn_definition,
      definition=definition,
      model=ai_state.model,
      prompt_label="event_scheduler",
      device="HM-PC",
      schema="-",
      prompt_strategy="1SHOT",
      verbose=false,
      capture_stdout=false
  )  

  println("\nEvaluation result:")
  display(eval_result)
end

