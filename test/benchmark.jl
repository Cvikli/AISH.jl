using JuliaLLMLeaderboard
using PromptingTools

const PT = PromptingTools

using AISH: initialize_ai_state
ai_state = initialize_ai_state()


model = "claude-3-5-sonnet-20240620"
# (prompt_label, model) = option
# schema = get(PT.MistralOpenAISchema(), model, PT.OpenAISchema())


# conversation = aigenerate(schema, definition["prompt"]; model, return_all = true)

# schema_lookup = Dict{String, Any}("claude-3-5-sonnet-20240620" => Ref(PT.MistralOpenAISchema()))

println("oksdfs")
fn_definitions = find_definitions("code_generation/")
println("ok")
println("okMMM")


evals = run_benchmark(; models = [model],
    prompt_labels = [ai_state.conversation[1].content],
    experiment = "", auto_save = true, verbose = true, device="HM-PC",
    num_samples = 10, http_kwargs = (; readtimeout = 150));




#%%
#%%
println(dirname(dirname(pathof(JuliaLLMLeaderboard))))
#%%

using AISH: initialize_ai_state
using JuliaLLMLeaderboard
using RelevanceStacktrace
using PromptingTools

fn_definition = dirname(dirname(pathof(JuliaLLMLeaderboard))) * "/" * joinpath("code_generation",
    "utility_functions",
    "event_scheduler",
    "definition.toml")
println(fn_definition)
definition = load_definition(fn_definition)["code_generation"]


ai_state = initialize_ai_state()
full_msg = definition["prompt"]
push!(ai_state.conversation,	PromptingTools.UserMessage("<USER>\n$(full_msg)\n</USER>"))
display(ai_state.conversation)
## Pick response generator based on the prompt_label
conversation = aigenerate(ai_state.conversation, model=ai_state.model, return_all = true)
@show "succcess!!"
## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)

#%%
#%%
println(full_msg)
#%%
ai_state
#%%


