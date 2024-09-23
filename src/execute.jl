
execute_code_block(cb::CodeBlock; no_confirm=false) = withenv("GTK_PATH" => "") do
  code = codestr(cb)
  if cb.type==:MODIFY || cb.type==:CREATE
    println("\e[32m$(get_shortened_code(code))\e[0m")
    cb.type==:CREATE && (print("\e[34mContinue? (y) \e[0m"); !(readchomp(`zsh -c "read -q '?'; echo \$?"`) == "0")) && return "Operation cancelled by user."
    return cmd_all_info(`zsh -c $code`)
  else
    !(lowercase(cb.language) in ["bash", "sh", "zsh"]) && return ""
    println("\e[32m$code\e[0m")
    if no_confirm
      return cmd_all_info(`zsh -c $code`)
    else
      print("\e[34mContinue? (y) \e[0m")
      return readchomp(`zsh -c "read -q '?'; echo \$?"`) == "0" ? cmd_all_info(`zsh -c $code`) : "Operation cancelled by user."
    end
  end
end

function cmd_all_info(cmd::Cmd, output=IOBuffer(), error=IOBuffer())
  err, process = "", nothing
  try
    process = run(pipeline(ignorestatus(cmd), stdout=output, stderr=error), wait=false)
  catch e
    err = "$e"
  end
  join(["$name=$str" for (name, str) in [("stdout", String(take!(output))), ("stderr", String(take!(error))), ("exception", err), ("exit_code", isnothing(process) ? "" : process.exitcode)] if !isempty(str)], "\n")
end
