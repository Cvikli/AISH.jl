@testset "LLM Parser Tests" begin
	@testset "File Creation" begin
			llm_output = """
			CREATE new_file.jl
			```julia
			function hello()
					println("Hello, world!")
			end
			```
			"""
			
			result = parse_llm_output(llm_output)
			
			@test length(result) == 1
			@test result[1].action == :create
			@test result[1].file_path == "new_file.jl"
			@test result[1].content == "function hello()\n    println(\"Hello, world!\")\nend\n"
	end

	@testset "File Modification" begin
			llm_output = """
			MODIFY existing_file.jl
			```julia
			// ... existing code ...
			function new_function()
					println("This is a new function")
			end
			```
			"""
			
			result = parse_llm_output(llm_output)
			
			@test length(result) == 1
			@test result[1].action == :modify
			@test result[1].file_path == "existing_file.jl"
			@test result[1].content == "// ... existing code ...\nfunction new_function()\n    println(\"This is a new function\")\nend\n"
	end
end
