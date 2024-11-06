using Test
using AISH
using EasyContext: Message, create_user_message, ConversationX, save_conversation

@testset "JSON Formatting" begin
    logdir = tempname()
    mkpath(logdir)
    try
        test_file = joinpath(logdir, "test.json")
        test_conv = ConversationX()
        test_conv(create_user_message("Test message"))
        
        # Save conversation
        save_conversation(test_file, test_conv)
        
        # Read the file content
        content = read(test_file, String)
        
        # Check for newlines and indentation
        @test occursin("\n", content)  # Should have line breaks
        @test occursin("  ", content)  # Should have indentation
        
        # Basic JSON structure validation
        @test startswith(content, "{")
        @test endswith(content, "}\n")
    finally
        rm(logdir, recursive=true, force=true)
    end
end
