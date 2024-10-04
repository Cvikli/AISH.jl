using Test
using AISH


@testset "Context Processing" begin
    user_question = "Test question"
    ctx_shell = "Shell context"
    ctx_codebase = "Codebase context"
    
    combined_context = AISH.context_combiner!(user_question, ctx_shell, ctx_codebase)
    
    @test occursin(user_question, combined_context)
    @test occursin(ctx_shell, combined_context)
    @test occursin(ctx_codebase, combined_context)
end

# ... (other test sets remain unchanged)
