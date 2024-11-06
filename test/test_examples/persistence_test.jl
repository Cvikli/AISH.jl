using Test
using AISH
using EasyContext: Message, create_user_message

@testset "Conversation Persistence" begin
    logdir = tempname()
    mkpath(logdir)
    try
        # First message
        model = SRWorkFlow(resume=false, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        model.conv_ctx(create_user_message("Hello"))
        model.persist(model.conv_ctx)
        msg_count = length(model.conv_ctx.messages)
        
        # Resume and verify first state
        model2 = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model2.conv_ctx.messages) == msg_count
        
        # Add AI message
        model2.conv_ctx(Message("assistant", "Hi there!"))
        model2.persist(model2.conv_ctx)
        msg_count2 = length(model2.conv_ctx.messages)
        
        # Resume and verify second state
        model3 = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model3.conv_ctx.messages) == msg_count2
        @test model3.conv_ctx.messages[end].content == "Hi there!"
    finally
        rm(logdir, recursive=true, force=true)
    end
end
