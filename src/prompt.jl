
# AI name have to be short, transcriptable not ordinary common word.
const ChatSH::String = "Orion"

const DEFAULT_SKILLS::Vector{Skill} = [
  create_file_skill, 
  modify_file_skill,
  shell_block_skill, 
  catfile_skill, 
]

SYSTEM_PROMPT(ChatSH; skills=[], guide_strs=[], ctx="") = """You are $ChatSH, an AI language model that specializes in assisting the user with his task using SHELL commands or codeblocks.

$(join([skill.description for skill in skills], "\n"))
$(highlight_code_guide)
$(highlight_changes_guide)
$(organize_file_guide)
$(shell_script_n_result_guide)

$(join(guide_strs, "\n"))

$(dont_act_chaotic)
$(refactor_all)
$(simplicity_guide)

$(ambiguity_guide)

$(test_it)

$(no_loggers)
$(julia_specific_guide)

$(system_information)
$(ctx)

Follow KISS and SOLID principles.

$(conversaton_starts_here)
"""

