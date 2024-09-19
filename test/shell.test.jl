
content = """
Okay.
```sh
Here we go:
```julia
This is also included
```
And this is also included
```
```sh
Another shell block
```
```sh
Unclosed shell block
```julia
Nested block
```
```
"""

println(join(collect(keys(extract_shell_commands(content))), "\n\n"))
@assert length(keys(extract_shell_commands(content))) == 3
@show first(collect(keys(extract_shell_commands(content))))
@assert last(keys(extract_shell_commands(content))) == """Here we go:
```julia
This is also included
```
And this is also included"""
@assert collect(keys(extract_shell_commands(content)))[2] == "Another shell block"
@assert last(keys(extract_shell_commands(content))) == """Unclosed shell block
```julia
Nested block
```"""

#%%
using AISH
content = """Certainly! Let's analyze the issues and fix the `extract_and_preprocess_shell_scripts` function to address all the problems we're seeing. Here's an improved version of the function:
```sh
meld ./src/shell_processing.jl <(cat <<'EOF'
some interesting code
extractor.in_sh_block && startswith(line, "```")
    command = join(extractor.current_command, '\n')
elseif extractor.in_sh_block && !startswith(line, "```sh")
end_of_things
```
So we have this.
"""
extractor = AISH.ShellScriptExtractor()
res = AISH.extract_and_preprocess_shell_scripts(content, extractor)
@show res
clipboard(res)
#%%