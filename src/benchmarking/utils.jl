function extract_sh_block_to_julia_code(input_string)
	@show "input_string"
	println(input_string)
code_block_regex = r"```sh\n(.*?)```\n"s
m = match(code_block_regex, input_string)
m === nothing && return input_string

code_content = m.captures[1]
julia_code = replace(code_content, r".*?\"EOL\"\n"s => "")
julia_code = replace(julia_code, r"\nEOL.*"s => "")

return replace(input_string, code_block_regex => "```julia\n$julia_code\n```")
end

print_score(res) = begin
    if res isa Dict
        println("Parsed: $(res["parsed"]) Executed: $(res["executed"]), P: $(res["unit_tests_passed"])/$(res["unit_tests_count"]), E: $(res["examples_executed"])/$(res["examples_count"]), $(res["elapsed_seconds"])s, \$$(res["cost"]) Label: $(res["prompt_label"])")
    else
        println("Parsed: $(res.parsed) Executed: $(res.executed), P: $(res.unit_tests_passed)/$(res.unit_tests_count), E: $(res.examples_executed)/$(res.examples_count), $(res.elapsed_seconds)s, \$$(res.cost) Label: $(res.prompt_label)")
    end
end

