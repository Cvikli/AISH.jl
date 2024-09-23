function execute(cmd::Cmd)
  out = Pipe()
  err = Pipe()

  process = run(pipeline(ignorestatus(cmd), stdout=out, stderr=err))
  close(out.in)
  close(err.in)
	stdoutt = @async String(read(out))
	stderrt = @async String(read(err))
	return (
			stdout = wait(stdoutt),
			stderr = wait(stderrt),
			code = process.exitcode
	)
end

q= execute(`ls`)
@show q
@show execute(`sh -c "ls"`)
@show execute(`ls --invalid-option`)