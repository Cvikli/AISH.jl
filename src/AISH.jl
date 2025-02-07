
module AISH

const PROGRAM_NAME = "AISH"

using BoilerplateCvikli: @async_showerr
using EasyContext: greet
using EasyContext: update_last_user_message_meta
using EasyContext: add_error_message!
using EasyContext: wait_user_question
using EasyContext: QueryWithHistory
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
using EasyContext: merge_git
using EasyContext: WorkspaceCTX, JuliaCTX, julia_ctx_2_string, workspace_ctx_2_string, get_tool_results
using EasyContext: workspace_format_description_raw
using EasyContext: execute
using EasyContext: context_combiner
using EasyContext: ChangeTracker, Context
using EasyContext
using ArgParse

abstract type Workflow end

include("config.jl")
include("utils.jl")
include("prompt.jl")

include("agents/flow.jl")
include("agents/std_flow.jl")
include("agents/selfreflect_flow.jl")

include("interfaces/readline/readline.jl")
include("interfaces/repl/repl_aish.jl")


# include("precompile_scripts.jl")

end # module AISH
