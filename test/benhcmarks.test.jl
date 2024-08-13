
a= """
ys try to use the sh blocks that was told to you to solve the tasks! \n\nWith these informations in mind you can communicate with the user from here!\nUser requests arrive these are what you have to fulfill.\n\n===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===\n2024-08-02T13:38:58.410 [user]: are the any chance that randomly I save the systemprompt again?\n===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===\n2024-08-02T13:39:47.852 [ai]: To investigate whether there's a chance of randomly saving the system prompt again, let's review the relevant code. We'll focus on the functions related to saving messages and updating the system prompt.\n\nFirst, let's look at the `save_message` function in the `src/messages.jl` file:\n\n```sh\nmeld src/messages.jl <(cat <<-\"EOL\"\nfunction save_message(state::AIState, role, message)\n    mkpath(CONVERSATION_DIR)\n    conversation_id = state.selected_conv_id\n    message_separator = get_message_separator(conversation_id)\n    existing_file = get_conversation_filename(conversation_id)\n\n    if isnothing(existing_file)\n        first_user_message = cur_conv(state)[2]\n        sanitized_chars = strip(replace(replace(first(first_user_message.content, 32), r\"[^\\w\\s-]\" => \"_\"), r\"\\s+\" => \"_\"), '_')\n        state.conversation_sentences[conversation_id] = sanitized_chars\n        filename = joinpath(CONVERSATION_DIR, \"\$(Dates.format(first_user_message.timestamp, \"yyyy-mm-dd_HH:MM:SS\"))_\$(sanitized_chars)_\$(conversation_id).log\")\n    else\n        filename = existing_file\n    end\n    if length(cur_conv(state)) >= 2\n        open(filename, isnothing(existing_file) ? \"w\" : \"a\") do file\n            if isnothing(existing_file) || length(cur_conv(state)) == 2\n                for msg in cur_conv(state)\n                    println(file, \"\$(msg.timestamp) [\$(msg.role)]: \$(msg.content)\")\n                    println(file, message_separator)\n                end\n            else\n                println(file, \"\$(now()) [\$(role)]: \$(message)\")\n                println(file, message_separator)\n            end\n        end\n    end\nend\nEOL\n)\n```\n```sh_run_results\n(stdout = \"\", stderr = \"\", exit_code = 0, exception = nothing)\n```\n\n\nNow, let's examine the `update_system_prompt!` function in the `src/AI_struct.jl` file:\n\n```sh\nmeld src/AI_struct.jl <(cat <<-\"EOL\"\n# Update system prompt\nfunction update_system_prompt!(state::AIState)\n    new_system_prompt = SYSTEM_PROMPT()\n    cur_conv(state)[1] = Message(now(), :system, new_system_prompt)\n    println(\"\\e[33mSystem prompt updated due to file changes.\\e[0m\")\nend\nEOL\n)\n```\n```sh_run_results\n(stdout = \"\", stderr = \"\", exit_code = 0, exception = nothing)\n```\n\n\nBased on this code, we can conclude:\n\n1. The system prompt is not directly saved using the `save_message` function. It's only updated in memory within the `update_system_prompt!` function.\n\n2. The `save_message` function is designed to save messages to a file, but it has a condition `if length(cur_conv(state)) >= 2` before writing anything. This means it won't save anything if there's only one message (which would be the system prompt) in the conversation.\n\n3. When saving messages, it checks if the file is new (`isnothing(existing_file)`) or if it's the second message in the conversation (`length(cur_conv(state)) == 2`). In these cases, it writes all messages, including the system prompt. Otherwise, it only appends the new message.\n\n4. The `update_system_prompt!` function is called in the `process_question` function in `src/process_query.jl`, which happens after processing each user query.\n\nGiven this implementation, there are a few scenarios where the system prompt might be saved again:\n\n1. When starting a new conversation (creating a new file).\n2. When the second message in a conversation is being saved.\n3. If the system prompt is updated due to file changes, and then a new user message triggers the saving process.\n\nHowever, this is not random. It happens in specific, deterministic situations. The system prompt won't be randomly saved again during normal conversation flow after the initial save.\n\nTo prevent unnecessary repeated saves of the system prompt, you could modify the `save_message` function to only save non-system messages after the initial save. If you want to implement this change, let me know, and I can provide the modified code.\n===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===\n"
"""
strip.(split(a, "===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===", keepempty=false))

#%%

function extract_julia_code(md)
    code_blocks = []
    in_code_block = false
    
    for line in split(md, '\n')
        stripped_line = strip(line)
        
        if startswith(stripped_line, "```julia")
            in_code_block = true
        elseif startswith(stripped_line, "```") && in_code_block
            in_code_block = false
        elseif in_code_block
            push!(code_blocks, line)
        end
    end
    
    return join(code_blocks, '\n')
end
@test extract_julia_code("""```julia
x = 1
```""") == "x = 1"
md_example = """
Here is some text.

```julia
println("Hello, World!")
```
More text here.

```julia
x = 1 + 1
```

End of document.
"""
@test extract_julia_code(md_example) == """println("Hello, World!")
x = 1 + 1"""
@test extract_julia_code("No code blocks here.") == ""

# Fourth unit test: Test with code blocks that don't belong to Julia
@test extract_julia_code("""```python
print('Hello')
```""") == ""

@test extract_julia_code("""```julia
a = 3
b = 4
a + b
```""") == "a = 3
b = 4
a + b"
#%%
extract_julia_code(# Second unit test: Test extraction of multiple code blocks
md_example = """
Here is some text.

```julia
println("Hello, World!")
```
More text here.

```julia
x = 1 + 1
```

End of document.
"""
@test extract_julia_code(md_example) == """println("Hello, World!")
x = 1 + 1""")
#%%
unit_tests = ["# First unit test: Test extraction of single code block\n@test extract_julia_code(\"\"\"```julia\nx = 1\n```\"\"\") == \"x = 1\"\n", "# Second unit test: Test extraction of multiple code blocks\nmd_example = \"\"\"\nHere is some text.\n\n```julia\nprintln(\"Hello, World!\")\n```\nMore text here.\n\n```julia\nx = 1 + 1\n```\n\nEnd of document.\n\"\"\"\n@test extract_julia_code(md_example) == \"\"\"println(\"Hello, World!\")\nx = 1 + 1\"\"\"\n", "# Third unit test: Test with no Julia code blocks\n@test extract_julia_code(\"No code blocks here.\") == \"\"\n", "# Fourth unit test: Test with code blocks that don't belong to Julia\n@test extract_julia_code(\"\"\"```python\nprint('Hello')\n```\"\"\") == \"\"\n", "# Fifth unit test: Test preservation of newline within a Julia code block\n@test extract_julia_code(\"\"\"```julia\na = 3\nb = 4\na + b\n```\"\"\") == \"a = 3\nb = 4\na + b\"\n"]
println.(unit_tests)
;

#%%


using Test
using Statistics

function weather_data_analyzer(temps)
    if isempty(temps)
        return (; average=nothing, max=nothing, min=nothing, trend=nothing)
    end

    avg = mean(temps)
    max_temp = maximum(temps)
    min_temp = minimum(temps)

    # Calculate the trend
    if length(temps) > 1
        first_half = temps[1:div(length(temps), 2)]
        second_half = temps[div(length(temps), 2)+1:end]
        @show mean(second_half) , mean(first_half)
        if mean(second_half) > mean(first_half)
            trend = :increasing
        elseif mean(second_half) < mean(first_half)
            trend = :decreasing
        else
            trend = :stable
        end
    else
        trend = :stable
    end

    return (; average=avg, max=max_temp, min=min_temp, trend=trend)
end
println(@test weather_data_analyzer([24, 23, 22, 21, 20]) == (average=22, max=24, min=20, trend=:decreasing))
println(@test weather_data_analyzer([20.0, 22.0, 25.0, 23.0, 21.0]) == (average=22.2, max=25.0, min=20.0, trend=:stable))
println(@test weather_data_analyzer(22.0ones(5)) == (average=22, max=22, min=22, trend=:stable))
#%%
mean((20.0, 22.0, 25.0)),mean((23.0, 21.0))
#%%

unit_tests = ["# Test 1: Check average, max, and min for a regular dataset.\n@test weather_data_analyzer([20.0, 22.0, 25.0, 23.0, 21.0]) == (average=22.2, max=25.0, min=20.0, trend=:stable)\n", "# Test 2: Check for an empty dataset.\n@test weather_data_analyzer([]) == (average=nothing, max=nothing, min=nothing, trend=nothing)\n", "# Test 3: Identify increasing trend.\n@test weather_data_analyzer([20., 21.,22., 23., 24.]) == (average=22., max=24., min=20., trend=:increasing)\n", "# Test 4: Identify decreasing trend.\n@test weather_data_analyzer([24, 23, 22, 21, 20]) == (average=22, max=24, min=20, trend=:decreasing)\n", "# Test 5: Check for a stable trend.\n@test weather_data_analyzer(22.0ones(5)) == (average=22, max=22, min=22, trend=:stable)\n"]

println.(unit_tests)



#%%
using Statistics

function weather_data_analyzer(temps)
    if isempty(temps)
        return (; average=nothing, max=nothing, min=nothing, trend=nothing)
    end

    avg = mean(temps)
    max_temp = maximum(temps)
    min_temp = minimum(temps)

    trend = if all(temps[i] <= temps[i+1] for i in 1:length(temps)-1)
        :increasing
    elseif all(temps[i] >= temps[i+1] for i in 1:length(temps)-1)
        :decreasing
    else
        :stable
    end

    return (; average=avg, max=max_temp, min=min_temp, trend=trend)
end
weather_data_analyzer([20.0, 22.0, 25.0, 23.0, 21.0])

#%%
println("using Statistics\n\nfunction weather_data_analyzer(temps)\n    if isempty(temps)\n        return (; average=nothing, max=nothing, min=nothing, trend=nothing)\n    else\n        average = mean(temps)\n        max_temp = maximum(temps)\n        min_temp = minimum(temps)\n        trend = if all(diff(temps) .> 0)\n            :increasing\n        elseif all(diff(temps) .< 0)\n            :decreasing\n        else\n            :stable\n        end\n        return (; average=average, max=max_temp, min=min_temp, trend=trend)\n    end\nend\n")
#%%
prompt = "You are given a list of daily temperature data `temps` (numbers). Write a function `weather_data_analyzer` that performs statistical analyses on this data (use `Statistics` package). The function should return results in named tuple (construct it with `(; key1=value1,key2=value2)` syntax) containing the `average`, `max`, `min` temperatures, and a `trend` (can be only: `:increasing`, `:decreasing`, or `:stable`). If the list is empty, the function should return a named tuple with all values set to `nothing`."
#%%
"""You are given a markdown-formatted text `md`. 
Write a function `q_and_a_extractor` to extract all text in the markdown sections Question and Answer (starting with `# Question` and `# Answer`, respectively) 
    and return the answer in a tuple like `(question,answer)`. 
    Strip any leading spaces and newlines from the extracted text."""
#%%
using Test
# function q_and_a_extractor(md::AbstractString)
#         question = match(r"(?<=# Question\n).*?(?=\n# [A-Za-z]+|$)"s, md)
#         answer   = match(r"(?<=# Answer\n).*?(?=\n# [A-Za-z]+|$)"s, md)
        
#         return (question === nothing ? "" : strip(question.match)),
#             (answer === nothing ? "" : strip(answer.match))
# end
function q_and_a_extractor(md)
    question_pattern = r"#\s*Question\s*\n(.*?)(?=#|\z)"s
    answer_pattern = r"#\s*Answer\s*\n(.*?)(?=#|\z)"s
    
    question_match = match(question_pattern, md)
    answer_match = match(answer_pattern, md)
    
    question = question_match === nothing ? "" : strip(question_match.captures[1])
    answer = answer_match === nothing ? "" : strip(answer_match.captures[1])
    
    return (question, answer)
end
md1 = """
# Question
What is 2 + 2?

# Answer
2 + 2 is 4.
"""
@test q_and_a_extractor(md1) == ("What is 2 + 2?", "2 + 2 is 4.")

md2 = """
# Question
What is the speed of light?

# Another Section
Some unrelated text.
"""
@test q_and_a_extractor(md2) == ("What is the speed of light?","")

md3 = """
# Introduction
Some introduction.

# Answer
Speed of light is approximately 299,792 km/s.
"""
@test q_and_a_extractor(md3) == ("", "Speed of light is approximately 299,792 km/s.")
md4 = """
# Question
First question?

# Answer
First answer.

# Question
Second question?

# Answer
Second answer.
"""
@test q_and_a_extractor(md4) == ("First question?", "First answer.")
md5 = """
# Question

  What is the largest ocean?

# Answer
  
  The Pacific Ocean is the largest.

"""
@test q_and_a_extractor(md5) == ("What is the largest ocean?", "The Pacific Ocean is the largest.")
#%%
#%%

t1 = "# Test 1: Check if typical Q&A format is extracted correctly.\nmd1 = \"\"\"\n# Question\nWhat is 2 + 2?\n\n# Answer\n2 + 2 is 4.\n\"\"\"\n@test q_and_a_extractor(md1) == (\"What is 2 + 2?\", \"2 + 2 is 4.\")\n"
md2 = "\"\"\"\n# Question\nWhat is the speed of light?\n\n# Another Section\nSome unrelated text.\n\"\"\"\n@test q_and_a_extractor(md2) == (\"What is the speed of light?\",\"\")\n"
md3 = "\"\"\"\n# Introduction\nSome introduction.\n\n# Answer\nSpeed of light is approximately 299,792 km/s.\n"
# t1 = "# Test 1: Check if typical Q&A format is extracted correctly.\nmd1 = \"\"\"\n# Question\nWhat is 2 + 2?\n\n# Answer\n2 + 2 is 4.\n\"\"\"\n@test q_and_a_extractor(md1) == (\"What is 2 + 2?\", \"2 + 2 is 4.\")\n"

println(t1)
#%%

unit_tests = ["# Test 1: Check if typical Q&A format is extracted correctly.\nmd1 = \"\"\"\n# Question\nWhat is 2 + 2?\n\n# Answer\n2 + 2 is 4.\n\"\"\"\n@test q_and_a_extractor(md1) == (\"What is 2 + 2?\", \"2 + 2 is 4.\")\n", "# Test 2: Handle input with no Answer section.\nmd2 = \"\"\"\n# Question\nWhat is the speed of light?\n\n# Another Section\nSome unrelated text.\n\"\"\"\n@test q_and_a_extractor(md2) == (\"What is the speed of light?\",\"\")\n", "# Test 3: Handle input with no Question section.\nmd3 = \"\"\"\n# Introduction\nSome introduction.\n\n# Answer\nSpeed of light is approximately 299,792 km/s.\n\"\"\"\n@test q_and_a_extractor(md3) == (\"\", \"Speed of light is approximately 299,792 km/s.\")\n", "# Test 4: Handle multiple Question and Answer sections.\nmd4 = \"\"\"\n# Question\nFirst question?\n\n# Answer\nFirst answer.\n\n# Question\nSecond question?\n\n# Answer\nSecond answer.\n\"\"\"\n@test q_and_a_extractor(md4) == (\"First question?\", \"First answer.\")\n", "# Test 5: Handle extra spaces before and after text.\nmd5 = \"\"\"\n# Question\n\n  What is the largest ocean?\n\n# Answer\n  \n  The Pacific Ocean is the largest.\n\n\"\"\"\n@test q_and_a_extractor(md5) == (\"What is the largest ocean?\", \"The Pacific Ocean is the largest.\")\n"]
println.(unit_tests)
;

#%%
println.(["q_and_a_extractor(\"# Question\nWhat is the capital of France?\n\n# Answer\nThe capital of France is Paris.\n\")", "q_and_a_extractor(\"\")", "q_and_a_extractor(strip(\"   # Question   \"))"]
);
#%%


get_id_from_file(filename) = (m = match(r"^\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(?<id>.+)_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.log$", filename); return m !== nothing ? m[:id] : "")


get_id_from_file("2024-08-02_13:38:58_are_the_any_chance_that_randomly_734b7fee-074c-480e-8c10-5264c314f9ce.log")
#%%
function to_pig_latin(word::AbstractString)
  vowels = "aeiouAEIOU"
  first_vowel_idx = findfirst(c -> c in vowels, word)
  if isnothing(first_vowel_idx) || first_vowel_idx == 1
    return word * "ay"
  else
    return word[first_vowel_idx:end] * word[1:first_vowel_idx-1] * "ay"
  end
end
function pig_latinify(words::Vector{<:AbstractString})
  transform = similar(words)
  Threads.@threads for i in 1:length(words)
    transform[i] = to_pig_latin(words[i])
   end
   return transform
end



#%%
function separate_paren_groups(paren_string::String)::Vector{String}
    result = String[]
    current_group = ""
    depth = 0
    
    for char in paren_string
        if char == '('
            depth += 1
            if depth == 1
                current_group = "("
            else
                current_group *= "("
            end
        elseif char == ')'
            depth -= 1
            current_group *= ")"
            if depth == 0
                push!(result, current_group)
                current_group = ""
            end
        elseif !isspace(char)
            current_group *= char
        end
    end
    
    return result
end
separate_paren_groups("( ) (( )) (( )( ))")

#%% 9
function rolling_max(numbers::Vector{Int})::Vector{Int}
    if isempty(numbers)
        return Int[]
    end
    
    result = similar(numbers)
    current_max = numbers[1]
    result[1] = current_max
    
    for i in 2:length(numbers)
        current_max = max(current_max, numbers[i])
        result[i] = current_max
    end
    
    return result
end
rolling_max([1, 2, 3, 2, 3, 4, 2])

#%% 83
function starts_one_ends(n::Int)::Int
    if n < 1
        return 0
    elseif n == 1
        return 1
    else
        # Numbers starting with 1: 10^(n-1)
        # Numbers ending with 1: 9 * 10^(n-2)
        # Numbers both starting and ending with 1: 10^(n-2)
        # We subtract 10^(n-2) to avoid double counting
        return 10^(n-1) + 9 * 10^(n-2) - 10^(n-2)
    end
end
starts_one_ends(5)

#%% 91
# is_bored(s::String)::Int

# You'll be given a string of words, and your task is to count the number of
# boredoms. A boredom is a sentence that starts with the word "I". Sentences are
# delimited by '.', '?' or '!'.
function is_bored(s::String)::Int
    # Split the string into sentences
    sentences = split(s, r"[.!?]")
    
    # Count sentences starting with "I "
    boredom_count = count(sentence -> startswith(strip(sentence), "I "), sentences)
    
    return boredom_count
end
using Test
is_bored("Hello world")
is_bored("The sky is blue. The sun is shining. I love this weather")
@show @test is_bored("Hello world") == 0
@show @test is_bored("Is the sky blue?") == 0
@show @test is_bored("I love It !") == 1
@show @test is_bored("bIt") == 0
@show @test is_bored("I feel good today. I will be productive. will kill It") == 2
@show @test is_bored("You and I are going for a walk") == 0

#%%

function even_odd_count(num::Int)::Tuple{Int, Int}
    even_count = 0
    odd_count = 0
    
    # Handle negative numbers by taking the absolute value
    num = abs(num)
    
    # Handle the case when num is 0
    if num == 0
        return (1, 0)
    end
    
    while num > 0
        digit = num % 10
        if digit % 2 == 0
            even_count += 1
        else
            odd_count += 1
        end
        num ÷= 10  # Integer division to move to the next digit
    end
    
    return (even_count, odd_count)
end

