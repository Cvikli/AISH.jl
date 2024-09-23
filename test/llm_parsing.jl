
using Test
using AISH
using AISH: ShellScriptExtractor, extract_and_preprocess_shell_scripts
using AISH: execute_single_shell_command

@testset "LLM Parser Tests" begin
	filepath = "test/test_examples/new_file.jl"
    @testset "File Creation" begin
        llm_output = """
        CREATE $filepath
        ```julia
        function hello()
            println("Hello, world!")
        end
        ```
        """

        extractor = ShellScriptExtractor()
        result = extract_and_preprocess_shell_scripts(llm_output, extractor)

        @test !isnothing(result)
        @test result.type == :CREATE
        @test result.file_path == filepath
        @test trim(result.pre_content) == "function hello()\n    println(\"Hello, world!\")\nend"

        # Execute the code block and check if the file is created
        execute_single_shell_command(result, no_confirm=true)
        @test isfile(filepath)
        @test read(filepath, String) == "function hello()\n    println(\"Hello, world!\")\nend\n"

        # rm(filepath)
    end

    @testset "File Creation with Multiple Files" begin
        llm_output = """
        CREATE file1.jl
        ```julia
        println("File 1")
        ```

        Some random text here.

        CREATE file2.jl
        ```julia
        println("File 2")
        ```
        """

        extractor = ShellScriptExtractor()
        result1 = extract_and_preprocess_shell_scripts(llm_output, extractor)
        result2 = extract_and_preprocess_shell_scripts(llm_output, extractor)

        @test !isnothing(result1)
        @test !isnothing(result2)
        @test result1.type == :CREATE
        @test result1.file_path == "file1.jl"
        @test result1.pre_content == "println(\"File 1\")\n"
        @test result2.type == :CREATE
        @test result2.file_path == "file2.jl"
        @test result2.pre_content == "println(\"File 2\")\n"

        # Execute the code blocks and check if the files are created
        execute_single_shell_command(result1, no_confirm=true)
        execute_single_shell_command(result2, no_confirm=true)
        @test isfile("file1.jl")
        @test isfile("file2.jl")
        @test read("file1.jl", String) == "println(\"File 1\")\n"
        @test read("file2.jl", String) == "println(\"File 2\")\n"

        # Clean up
        rm("file1.jl")
        rm("file2.jl")
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

    #     extractor = ShellScriptExtractor()
    #     result = extract_and_preprocess_shell_scripts(llm_output, extractor)

    #     @test !isnothing(result)
    #     @test result.type == :MODIFY
    #     @test result.file_path == "existing_file.jl"
    #     @test result.pre_content == "# ... existing code ...\nfunction new_function()\n    println(\"This is a new function\")\nend\n"

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

