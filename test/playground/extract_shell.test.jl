using Test
using ReTestItems

@testitem "Shell script extractor tests" begin
    using Random
    import AISH

    @testset "Basic extraction" begin
        content = """
        Some text
        ```sh
        echo "Hello, World!"
        ```
        More text
        ```sh
        ls -l
        cat file.txt
        ```
        """
        extracted = AISH.extract_shell_commands(content)
        @test length(extracted) == 2
        @test haskey(extracted, "echo \"Hello, World!\"")
        @test haskey(extracted, "ls -l\ncat file.txt")
    end

    @testset "Chunked extraction" begin
        content = """
        Some text
        ```sh
        echo "Hello, World!"
        ```
        More text
        ```sh
        ls -l
        cat file.txt
        ```
        """
        chunks = [content[1:30], content[31:60], content[61:end]]
        
        extractor = AISH.CodeBlockExtractor()
        for chunk in chunks
            AISH.extract_and_preprocess_shell_scripts(chunk, extractor; mock=true)
        end

        extracted_scripts = extractor.shell_scripts
        @test length(extracted_scripts) == 2
        @test any(cmd -> strip(fetch(cmd)) == "echo \"Hello, World!\"", values(extracted_scripts))
        @test any(cmd -> strip(fetch(cmd)) == "ls -l\ncat file.txt", values(extracted_scripts))
    end

    @testset "Edge cases" begin
        @testset "Empty content" begin
            extracted = AISH.extract_shell_commands("")
            @test isempty(extracted)
        end
        @testset "Non-shell block things" begin
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
            extracted = AISH.extract_shell_commands(content)
            extractor = CodeBlockExtractor()
            res = extract_and_preprocess_shell_scripts(extractor, content)
            @show res

        end

        @testset "No shell blocks" begin
            content = "Just some text without any shell blocks."
            extracted = AISH.extract_shell_commands(content)
            @test isempty(extracted)
        end

        @testset "Incomplete shell block" begin
            content = "```sh\necho \"incomplete"
            extracted = AISH.extract_shell_commands(content)
            @test isempty(extracted)
        end

        @testset "Nested code blocks" begin
            content = """
            ```sh
            echo "Outer block"
            ```python
            print("Inner block")
            ```
            echo "Still in outer block"
            ```
            """
            extracted = AISH.extract_shell_commands(content)
            @test length(extracted) == 1
            @test haskey(extracted, "echo \"Outer block\"\n```python\nprint(\"Inner block\")\n```\necho \"Still in outer block\"")
        end
    end

    @testset "Comparison with original method" begin
        content = """
        Some text
        ```sh
        echo "Test 1"
        ```
        More text
        ```sh
        echo "Test 2"
        ls -l
        ```
        """
        original_extracted = AISH.extract_shell_commands(content)

        extractor = AISH.CodeBlockExtractor()
        AISH.extract_and_preprocess_shell_scripts(content, extractor; mock=true)
        chunked_extracted = Dict(cmd => fetch(task) for (cmd, task) in extractor.shell_scripts)

        @test Set(keys(original_extracted)) == Set(keys(chunked_extracted))
        for key in keys(original_extracted)
            @test strip(original_extracted[key]) == strip(chunked_extracted[key])
        end
    end
end

