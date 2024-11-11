using Test
using AISH
using EasyContext
using EasyContext: WebMessage, create_user_message, save_conversation, load_conversation
using Dates

# Helper to create a WebMessage
create_web_message(role, content) = WebMessage(;
    timestamp=now(),
    role=Symbol(role),
    content=content,
    itok=0,
    otok=0,
    cached=0,
    cache_read=0,
    price=0.0f0,
    elapsed=0.0f0
)

@testset "Conversation Persistence" begin
    logdir = tempname()
    mkpath(logdir)
    try
        # Basic persistence test
        conv = initSession(sys_msg="Test system prompt")
        conv(create_web_message("user", "Hello"))  # Use WebMessage consistently
        
        filepath = joinpath(logdir, "test.json")
        save_conversation(filepath, conv)
        msg_count = length(conv.messages)
        
        # Resume and verify first state
        loaded_conv = load_conversation(filepath)
        @test length(loaded_conv.messages) == msg_count
        
        # Test large message
        large_msg = "X" ^ 10000
        conv(create_web_message("assistant", large_msg))
        save_conversation(filepath, conv)
        
        # Resume and verify large message
        loaded_conv2 = load_conversation(filepath)
        @test loaded_conv2.messages[end].content == large_msg

        # Test multiple rapid persists
        for i in 1:5
            conv(create_web_message("user", "Message $i"))
            save_conversation(filepath, conv)
        end
        msg_count3 = length(conv.messages)

        # Verify all messages persisted
        loaded_conv3 = load_conversation(filepath)
        @test length(loaded_conv3.messages) == msg_count3
        @test loaded_conv3.messages[end].content == "Message 5"
    finally
        rm(logdir, recursive=true, force=true)
    end
end

# Test resume with missing/corrupted persistence
@testset "Persistence Edge Cases" begin
    logdir = tempname()
    mkpath(logdir)
    try
        filepath = joinpath(logdir, "test.json")
        
        # Test with non-existent file
        @test_throws SystemError load_conversation(filepath)
        
        # Test with corrupted file
        write(filepath, "{corrupted json")
        @test_throws ArgumentError load_conversation(filepath)
        
        # Test with partial write
        conv = initSession(sys_msg="Test")
        conv(create_web_message("user", "Test message"))
        save_conversation(filepath, conv)
        truncate(filepath, filesize(filepath) ÷ 2)
        
        @test_throws ArgumentError load_conversation(filepath)
    finally
        rm(logdir, recursive=true, force=true)
    end
end

