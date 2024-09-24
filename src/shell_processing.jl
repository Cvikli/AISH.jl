
@kwdef mutable struct CodeBlockExtractor
    last_processed_index::Ref{Int} = Ref(0)
    shell_scripts::OrderedDict{String, Task} = OrderedDict{String, Task}()
    shell_results::OrderedDict{String, CodeBlock} = OrderedDict{String, CodeBlock}()
    full_content::String = ""
    skip_code_execution::Bool = false
    no_confirm::Bool = false
end


function extract_and_preprocess_codeblocks(new_content::String, extractor::CodeBlockExtractor; mock=false)
    # @show extractor
    extractor.full_content *= new_content
    lines = split(extractor.full_content[nextind(extractor.full_content, extractor.last_processed_index[]):end], '\n')
    current_command = String[]
    in_block = false
    cmd_type = :DEFAULT
    block_type = ""
    file_path = ""

    for (i, line) in enumerate(lines)
        if startswith(line, "MODIFY ")        
            file_path = String(strip(line[8:end]))
            cmd_type = :MODIFY
        elseif startswith(line, "CREATE ")
            file_path = String(strip(line[8:end]))
            cmd_type = :CREATE
        elseif startswith(line, "```") && !in_block
            in_block = true
            block_type = String(strip(line[4:end]))
        elseif in_block && length(line)>=3 && line[1:3] == "```" && (length(line)==3 || all(isspace, line[4:end]))
            command = join(current_command, '\n')
            cb=CodeBlock(;file_path, type=cmd_type, language=block_type, pre_content=command)
            extractor.shell_scripts[command] = @async_showerr preprocess(cb)
            current_command = String[]
            in_block = false
            cmd_type = :DEFAULT
            block_type = ""
            file_path = ""
            extractor.last_processed_index[]  = length(extractor.full_content)
            
            return cb
        elseif in_block
            push!(current_command, line)
        end
        
        # if !in_block
        #     last_processed_char += length(line) + 1  # +1 for the newline
        # end
    end

    return nothing
end

codeblock_runner(extractor::CodeBlockExtractor) = !extractor.skip_code_execution ? execute_shell_commands(extractor; no_confirm=extractor.no_confirm) : OrderedDict{String, CodeBlock}()

function execute_shell_commands(extractor::CodeBlockExtractor; no_confirm=false)
    for (command, task) in extractor.shell_scripts
        extractor.shell_results[command] = fetch(task)
        # @show processed_command
        output = execute_code_block(processed_command; no_confirm)
        push!(extractor.shell_results[command].run_results, output)
        println("\n\e[36mCommand:\e[0m $command")
        println("\e[36mOutput:\e[0m $output")
    end
end

reset!(extractor::CodeBlockExtractor) = begin
    extractor.last_processed_index=Ref(0) 
    empty!(extractor.shell_scripts)
    empty!(extractor.shell_results)
    extractor.full_content="" 
end

