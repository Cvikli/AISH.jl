
update_message_with_outputs(content) = return replace(content, r"```sh\n([\s\S]*?)\n```" => matchedtxt -> begin
  code = matchedtxt[7:end-3]
  output = execute_code_block(code)
  "$matchedtxt\n```sh_run_results\n$output\n```\n"
end)

execute_code_block(code) = withenv("GTK_PATH" => "") do
  if startswith(code, "meld")
    println("\e[32m$(get_shortened_code(code))\e[0m")
    return cmd_all_info(`zsh -c $code`)
  else
    println("\e[32m$code\e[0m")
    print("\e[34mContinue? (y) \e[0m")
    return readchomp(`zsh -c "read -q '?'; echo \$?"`) == "0" ? cmd_all_info(`zsh -c $code`) : "Operation cancelled by user."
  end
end


function cmd_all_info(cmd::Cmd, output=IOBuffer(), error=IOBuffer())
  err, process = "", nothing
  try
    process = run(pipeline(ignorestatus(cmd), stdout=output, stderr=error))
  catch e
    err = "$e"
  end
  join(["$name=$str" for (name, str) in [("stdout", String(take!(output))), ("stderr", String(take!(error))), ("exception", err), ("exit_code", isnothing(process) ? "" : process.exitcode)] if !isempty(str)], "\n")
end
