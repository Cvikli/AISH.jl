
using Test
using AISH
using AISH: CodeBlockExtractor, extract_and_preprocess_shell_scripts
using AISH: execute_single_shell_command

@testset "LLM Parser Tests" begin
	testpath="test/test_examples"
	filepath = "$(testpath)/new_file.jl"
    @testset "File Creation" begin
        llm_output = """
        CREATE $filepath
        ```julia
        function hello()
            println("Hello, world!")
        end
        ```
        """

        extractor = CodeBlockExtractor()
        result = extract_and_preprocess_shell_scripts(llm_output, extractor)

        @test !isnothing(result)
        @test result.type == :CREATE
        @test result.file_path == filepath
        @test strip(result.content) == "function hello()\n    println(\"Hello, world!\")\nend"

        # Execute the code block and check if the file is created
        execute_single_shell_command(result, no_confirm=true)
        @test isfile(filepath)
        @test read(filepath, String) == "function hello()\n    println(\"Hello, world!\")\nend\n"

        rm(filepath)
    end

    @testset "File Creation with Multiple Files" begin
			f1 = "$(testpath)/file1.jl"
			f2 = "$(testpath)/file2.jl"
        llm_output1 = """
				test
				CREATE $f1
				```julia
				println("File 1")
				```

				Some random text here.
				"""
				llm_output2 = """
				OK

				CREATE $f2
				```julia
				println("File 2")
				```
				testes
				"""

        extractor = CodeBlockExtractor()
        result1 = extract_and_preprocess_shell_scripts(llm_output1, extractor)

        @test !isnothing(result1)
        @test result1.type == :CREATE
        @test result1.file_path == f1
        @test strip(result1.content) == "println(\"File 1\")"

        execute_single_shell_command(result1, no_confirm=true)
        @test isfile(f1)
        @test read(f1, String) == "println(\"File 1\")\n"

        result2 = extract_and_preprocess_shell_scripts(llm_output2, extractor)
        @test !isnothing(result2)
        @test result2.type == :CREATE
        @test result2.file_path == f2
        @test strip(result2.content) == "println(\"File 2\")"

        execute_single_shell_command(result2, no_confirm=true)
        @test isfile(f2)
        @test read(f2, String) == "println(\"File 2\")\n"

        # Clean up
        rm(f1)
        rm(f2)
    end

    # @testset "File Modification" begin
    #     # Create a temporary file for modification
    #     write("existing_file.jl", "# Original content\n")

    #     llm_output = """
    #     MODIFY existing_file.jl
    #     ```julia
    #     # ... existing code ...
    #     function new_function()
    #         println("This is a new function")
    #     end
    #     ```
    #     """

    #     extractor = CodeBlockExtractor()
    #     result = extract_and_preprocess_shell_scripts(llm_output, extractor)

    #     @test !isnothing(result)
    #     @test result.type == :MODIFY
    #     @test result.file_path == "existing_file.jl"
    #     @test result.content == "# ... existing code ...\nfunction new_function()\n    println(\"This is a new function\")\nend\n"

    #     # Execute the code block and check if the file is modified
    #     execute_single_shell_command(result, no_confirm=true)
    #     @test isfile("existing_file.jl")
    #     modified_content = read("existing_file.jl", String)
    #     @test occursin("# Original content", modified_content)
    #     @test occursin("function new_function()", modified_content)
    #     @test occursin("println(\"This is a new function\")", modified_content)

    #     # Clean up
    #     rm("existing_file.jl")
    # end
end

