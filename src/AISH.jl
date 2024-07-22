# src/AISH.jl
module AISH

using REPL
using InteractiveUtils
using PromptingTools
using PromptingTools: SystemMessage, UserMessage

include("includes.jl")


start_conversation(state::AIState) = begin
	while isa(state.conversation[end], UserMessage); pop!(state.conversation); end
	println("Welcome to $ChatSH AI. Model: $(state.model)")
	println("Press [Enter] then you can start the conversation!")
  while true
    print("\e[36m➜ \e[0m ")  # teal arrow
    print("\e[1m")  # bold text
    # user_message = speech2text()
    # user_message = get_random_speech()
    user_message = readline_improved()
    print("\e[0m")  # reset text style
		user_message = strip(user_message)
	
		full_message = (!isempty(state.last_output) ? "<SYSTEM>\n$(state.last_output)\n</SYSTEM>\n" : "")	* 
									 (!isempty(user_message)      ? "<USER>\n$user_message\n</USER>"              : "")
		
			
		push!(state.conversation,	UserMessage(full_message))
		length(state.conversation) > 12 && (state.conversation = [state.conversation[1],state.conversation[4:end]...]) # Cut too long history... This could be also dinamic to allow longer history when the talks are shorter.
		# println(user_message)
		println()
		process_question(state)
  end
end






end # module AISH
