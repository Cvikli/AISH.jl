function communicate(cmd::Base.AbstractCmd, input="")
	inp = Pipe()
	out = Pipe()
	err = Pipe()

	process = run(pipeline(cmd, stdin=inp, stdout=out, stderr=err), wait=false)
	close(out.in)
	close(err.in)

	stdout = @async String(read(out))
	stderr = @async String(read(err))
	write(process, input)
	close(inp)
	wait(process)
	if process isa Base.ProcessChain
			exitcode = maximum([p.exitcode for p in process.processes])
	else
			exitcode = process.exitcode
	end

	return (
			stdout = fetch(stdout),
			stderr = fetch(stderr),
			code = exitcode
	)
end
# @show communicate(`cat`, "hello")
@show communicate(`sh -c "cat; echo errrr 1>&2; exit 3"`)
@show communicate(`sh -c "for i in {1..10}; do echo \$i; sleep 1; done"`)