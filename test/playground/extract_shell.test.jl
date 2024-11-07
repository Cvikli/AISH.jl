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

    @testset "Strange content" begin
        content = """
        Something...
        MODIFY ./README.md
        ```markdown
        # monaco-meld 

        A drop in replacement for meld with monaco diff. A lightweight Electron based app for fast diffing 2 files.

        ## Features

        - Hopefully lightweight, so fast start
        - Arrow based navigation
        - Alt + Up/Down: Navigate between changes
        - Alt + Left: Accept current change from right to left
        - Syntax highlighting with Monaco

        ## Usage

        Basic file comparison:
        ```sh
        ./monaco-meld-1.0.0.AppImage file1.js file2.js
        ```

        Compare file with stdin content:
        ```sh
        ./monaco-meld-1.0.0.AppImage file1.js <(echo "modified content")
        ```

        Compare with multiline content:
        ```sh
        ./monaco-meld-1.0.0.AppImage file1.js <(cat <<EOF
        new content here
        with multiple lines
        EOF
        )
        ```

        ## Building
        Processing diff with AI for higher quality...

        ```sh
        npm install
        npm run build
        ```

        ## Requirements

        Some might need to run .appImages on Ubuntu 24.04.

        ```sh
        sudo apt install libfuse2
        ```

        ## License
        ...
        ```
        Ende
        """
        original_extracted = AISH.extract_shell_commands(content)
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

