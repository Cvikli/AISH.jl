
module AISH

using BoilerplateCvikli: @async_showerr
using EasyContext: greet
using EasyContext: update_last_user_message_meta
using EasyContext: add_error_message!
using EasyContext: wait_user_question
using EasyContext: LLM_solve
using EasyContext: QuestionCTX
using EasyContext: print_project_tree
using EasyContext: context_combiner!
using EasyContext: LLM_reflect
using EasyContext: get_cache_setting
using EasyContext: init_workspace_context
using EasyContext: process_workspace_context
using EasyContext: process_julia_context
using EasyContext: cut_old_conversation_history!
using EasyContext: workspace_format_description, julia_format_guide
using EasyContext: last_msg
using EasyContext: Conversation, PersistableState
using EasyContext: merge_git
using EasyContext: WorkspaceCTX, JuliaCTX, julia_ctx_2_string, workspace_ctx_2_string, shell_ctx_2_string
using EasyContext: Workflow
using EasyContext: execute
using EasyContext: context_combiner
using EasyContext: ChangeTracker, Context
using EasyContext

include("config.jl")
include("utils.jl")
include("prompt.jl")

include("agents/selfreflect_flow.jl")
include("agents/std_flow.jl")

include("interfaces/cmd/cmd_arg_parser.jl")
include("interfaces/cmd/cmd.jl")
include("interfaces/repl/repl.jl")


# include("precompile_scripts.jl")

end # module AISH
