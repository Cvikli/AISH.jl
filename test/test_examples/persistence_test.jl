using Test
using AISH

@testset "Conversation Persistence" begin
    logdir = tempname()
    mkpath(logdir)
    try
        # First conversation
        start("Hello", logdir=logdir, no_confirm=true, loop=false)

        # Resume conversation
        model = SRWorkFlow(resume=true, project_paths=String[], logdir=logdir, show_tokens=false, silent=true, no_confirm=true)
        @test length(model.conv_ctx.messages) > 0  # Should have the previous conversation
    finally
        rm(logdir, recursive=true, force=true)
    end
end
