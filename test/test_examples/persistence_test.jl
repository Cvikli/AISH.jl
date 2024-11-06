using Test
using AISH
using EasyContext: Message, create_user_message

@testset "Conversation Persistence" begin
    logdir = tempname()
    mkpath(logdir)
    try
        # Basic persistence test
        model = SRWorkFlow(resume=false, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        model.conv_ctx(create_user_message("Hello"))
        model.persist(model.conv_ctx)
        msg_count = length(model.conv_ctx.messages)
        
        # Resume and verify first state
        model2 = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model2.conv_ctx.messages) == msg_count
        
        # Test large message
        large_msg = "X" ^ 10000
        model2.conv_ctx(Message("assistant", large_msg))
        model2.persist(model2.conv_ctx)
        
        # Resume and verify large message
        model3 = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test model3.conv_ctx.messages[end].content == large_msg

        # Test multiple rapid persists
        for i in 1:5
            model3.conv_ctx(Message("user", "Message $i"))
            model3.persist(model3.conv_ctx)
        end
        msg_count3 = length(model3.conv_ctx.messages)

        # Verify all messages persisted
        model4 = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model4.conv_ctx.messages) == msg_count3
        @test model4.conv_ctx.messages[end].content == "Message 5"
    finally
        rm(logdir, recursive=true, force=true)
    end
end

# Test resume with missing/corrupted persistence
@testset "Persistence Edge Cases" begin
    logdir = tempname()
    mkpath(logdir)
    try
        # Test with non-existent persistence file
        model = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model.conv_ctx.messages) > 0  # Should have system message at least
        
        # Test with corrupted persistence file
        model.conv_ctx(create_user_message("Test message"))
        model.persist(model.conv_ctx)
        
        # Corrupt the persistence file
        persistence_file = first(filter(f->endswith(f, ".json"), readdir(logdir, join=true)))
        write(persistence_file, "{corrupted json")
        
        # Should handle corrupted file gracefully
        model2 = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model2.conv_ctx.messages) > 0  # Should still have system message
        
        # Partially written file simulation
        model2.conv_ctx(create_user_message("Another test"))
        model2.persist(model2.conv_ctx)
        truncate(persistence_file, filesize(persistence_file) ÷ 2)  # Simulate partial write
        
        # Should handle partial file gracefully
        model3 = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model3.conv_ctx.messages) > 0
    finally
        rm(logdir, recursive=true, force=true)
    end
end

