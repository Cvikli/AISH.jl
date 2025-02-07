
# AI name have to be short, transcriptable not ordinary common word.
const ChatSH::String = "AISH StdFlow"



SYSTEM_PROMPT(ChatSH; guide_strs=[], ctx="") = """You are $ChatSH, an AI language model that specializes in assisting the user with his task using SHELL commands or codeblocks.

$(join(guide_strs, "\n"))
$(ctx)
"""

