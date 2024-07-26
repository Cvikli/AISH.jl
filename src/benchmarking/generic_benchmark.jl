using AISH: initialize_ai_state, safe_aigenerate
using JuliaLLMLeaderboard
using RelevanceStacktrace
using PromptingTools
using TOML

include("utils.jl")

function run_generic_benchmark(definition_file::String)
	println("Definition file: $definition_file")
	definition = TOML.parsefile(definition_file)["code_generation"]
	@show definition["name"]
	ai_state = initialize_ai_state()
	prompt = definition["prompt"]
	println(prompt)
	push!(ai_state.conversation, PromptingTools.UserMessage(prompt))

	conversation = safe_aigenerate(ai_state.conversation, model=ai_state.model, return_all=true)

	# Evaluate 1SHOT
	conversation_mod = deepcopy(conversation)
	conversation_mod[end] = PromptingTools.AIMessage(
						extract_sh_block_to_julia_code(conversation_mod[end].content),
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
			fn_definition=definition_file,
			definition=definition,
			model=ai_state.model,
			prompt_label=definition["name"],
			device="HM-PC",
			schema="-",
			prompt_strategy="1SHOT",
			verbose=true,
			capture_stdout=true
	)

	# println("\nEvaluation result:")
	# display(eval_result)
	print_score(eval_result)
	eval_result
end

#%%
# function to_pig_latin(word::String)
# 	vowels = ['a', 'e', 'i', 'o', 'u']
# 	if isempty(word)
# 			return word
# 	elseif lowercase(word[1]) in vowels
# 			return word * "way"
# 	else
# 			first_vowel_index = findfirst(char -> lowercase(char) in vowels, word)
# 			if isnothing(first_vowel_index)
# 					return word * "ay"
# 			else
# 					return word[first_vowel_index:end] * word[1:first_vowel_index-1] * "ay"
# 			end
# 	end
# end

# function pig_latinify(words::Vector{String})
# 	result = similar(words)
# 	@threads for i in eachindex(words)
# 			result[i] = to_pig_latin(words[i])
# 	end
# 	return result
# end