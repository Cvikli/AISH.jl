# src/AISH.jl
module AISH

using REPL
using InteractiveUtils
using PromptingTools
using PromptingTools: SystemMessage, UserMessage

include("includes.jl")



function extract_code(text)
  m = match(r"```sh([\s\S]*?)```", text)
  return m !== nothing ? strip(m.captures[1]) : nothing
end

start_conversation(state::AIState) = begin
	while isa(state.conversation[end], UserMessage); pop!(state.conversation); end
	println("Welcome to $ChatSH AI. Model: $(state.model)\n")
  while true
    print("\e[1m")  # bold text
    # user_message = speech2text()
    # user_message = get_random_speech()
    user_message = readline_improved()
    print("\e[0m")  # reset text style
		user_message = strip(user_message)
		println(user_message)
		println()
	
		full_message = (!isempty(state.last_output) ? "<SYSTEM>\n$(state.last_output)\n</SYSTEM>\n" : "")	* 
									 (!isempty(user_message)      ? "<USER>\n$user_message\n</USER>"              : "")
		push!(state.conversation,	UserMessage(full_message))
		@show state.conversation
		process_question(state)
  end
end






end # module AISH
