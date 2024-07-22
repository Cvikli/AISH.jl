process_question(state) = begin
  println("Thinking...")

  assistant_message = aigenerate(state.conversation, model=state.model)
  push!(state.conversation, assistant_message)
  println("\e[32m\$\e[0m $(assistant_message.content)")  # Green $ symbol
  println()

  code_blocks = extract_all_code(assistant_message.content)
  all_outputs = String[]

  if !isempty(code_blocks)
    for (index, code) in enumerate(code_blocks)
      println("\e[34mCode block $index:\e[0m")
      println("\e[2m$code\e[0m")
      println("\e[31mPress enter to execute this block, 'S' to skip, or 'Q' to quit.\e[0m")

      answer = lowercase(strip(readline()))
      if answer == "q"
        println("Execution cancelled.")
        break
      elseif answer in ["s", "n", "no"]
        println("Skipping this code block.")
        push!(all_outputs, "Output $index: [Skipped]")
        continue
      elseif answer !== ""
        println("Unknown command!!  If you want to run then don't send S neither Q")
      end

      try
        output = strip(read(`bash -c $code`, String))
        println("\e[2m$output\e[0m")
        push!(all_outputs, "Output $index:\n$output")
      catch error
        error_output = strip(sprint(showerror, error))
        println("\e[31mError: $error_output\e[0m")
        push!(all_outputs, "Output $index: [Error]\n$error_output")
        @warn("DANGEROUS AS no backtrace is printed here!!")
      end
    end

    state.last_output = join(all_outputs, "\n\n")
  else
    state.last_output = ""
  end

  println("\n\e[35mFinal Output:\e[0m")
  println(state.last_output)
end

function extract_all_code(text)
  code_blocks = []
  for m in eachmatch(r"```sh([\s\S]*?)```", text)
    code = strip(m.captures[1])
    push!(code_blocks, code)
  end
  return code_blocks
end
