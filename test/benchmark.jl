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
conversation_mod = deepcopy(conversation)
conversation_mod[end] = AIMessage(extract_julia_code(conversation_mod[end].content),
conversation_mod[end].status,
conversation_mod[end].tokens,
conversation_mod[end].elapsed,
conversation_mod[end].cost,
conversation_mod[end].log_prob,
conversation_mod[end].finish_reason,
conversation_mod[end].run_id,
conversation_mod[end].sample_id,
conversation_mod[end]._type,
)
eval_ = evaluate_1shot(;
conversation=conversation_mod,
    fn_definition,
    definition,
    ai_state.model,
    prompt_label="event_scheduler",
    device="HM-PC",
    schema="-",
    prompt_strategy = "1SHOT",
    verbose = false,
    ## important to set to false if you run in multi-threaded mode
    capture_stdout = false)

#%%
#%%
println(full_msg)
#%%
ai_state
#%%
#%%
println(conversation[end].content)
#%%
# function extract_julia_code(input_string)
#     # Regular expression to match the code block
#     code_block_regex = r"```sh\n(.*?)```"s
    
#     # Find the code block
#     m = match(code_block_regex, input_string)
#     # display(m)
#     if m === nothing
#         return "No code block found"
#     end
    
#     # Extract the code content
#     code_content = m.captures[1]
    
#     # Remove the bash command (everything up to and including the first EOL)
#     julia_code = replace(code_content, r".*? EOL\n"s => "")
    
#     # Remove the last line (julia event_scheduler.jl)
#     julia_code = replace(julia_code, r"\nEOL.*"s => "")
    
#     # Construct the modified string
#     modified_string = replace(input_string, code_block_regex => "```julia\n$julia_code\n```")
#     return modified_string
# end



;


#%%
textt = """
Certainly! I'll write a Julia function `event_scheduler` that checks for scheduling conflicts among events. Here's the implementation:

```sh
cat > event_scheduler.jl << EOL
using Dates

function event_scheduler(events::Vector{Tuple{String, String}})

    return "No conflicts"
end
EOL

julia event_scheduler.jl
```
test funciekn efeinfsehgehrse

```sh
# Test cases
events1 = [("2023-05-01 09:00", "2023-05-01 10:00"), ("2023-05-01 10:30", "2023-05-01 11:30")]
events2 = [("2023-05-01 09:00", "2023-05-01 10:30"), ("2023-05-01 10:00", "2023-05-01 11:00")]
events3 = Vector{Tuple{String, String}}()
```
fsefse sefsef sef sef sef sef

```sh
println(event_scheduler(events1))  # Should print: No conflicts
println(event_scheduler(events2))  # Should print: Conflict
println(event_scheduler(events3))  # Should print: No events
This script does the following:
```

1. We define the `event_scheduler` function that takes a vector of tuples, where each tuple contains start and finish times as strings.

This implementation should correctly handle the scheduling conflict check for the given events.
"""


