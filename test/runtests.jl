using Test
using AISH

@testset "Conversation Initialization" begin
    # Mock the necessary components
    workspace = AISH.WorkspaceLoader(["."])
    conversation = AISH.ConversationProcessorr(sys_msg="Test system message")
    
    @test conversation.messages[1].role == "system"
    @test conversation.messages[1].content == "Test system message"
end

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
