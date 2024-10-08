function extract_shell_commands(content::String)
  shell_commands = Dict{String, String}()
  lines = split(content, '\n')
  current_command = String[]
  in_sh_block = false
  nested_level = 0

  for line in lines
      if startswith(line, "```sh") && !in_sh_block
          in_sh_block = true
          nested_level = 1
      elseif in_sh_block
          if startswith(line, "```") && !startswith(line, "```sh")
              if occursin(r"^```\w+", line)  # Opening of a nested code block
                  nested_level += 1
              else  # Potential closing of a code block
                  nested_level -= 1
                  if nested_level == 0
                      command = join(current_command, '\n')
                      shell_commands[command] = ""
                      current_command = String[]
                      in_sh_block = false
                      continue
                  end
              end
          end
          push!(current_command, line)
      end
  end

  # Handle case where the last shell block wasn't closed
  if in_sh_block && !isempty(current_command)
      command = join(current_command, '\n')
      shell_commands[command] = ""
  end

  return shell_commands
end

function execute_shell_commands(shell_commands::Dict{String, String})
  for (code, _) in shell_commands
      output = execute_code_block(code)
      shell_commands[code] = output
  end
  return shell_commands
end
