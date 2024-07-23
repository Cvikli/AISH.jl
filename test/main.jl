using RelevanceStacktrace

using Revise
using AISH: start_conversation, initialize_ai_state

ai_state = initialize_ai_state()
# start_conversation(ai_state)
#%%

start_conversation(ai_state)


#%%

display(ai_state.conversation[1:end])

#%%
get(ENV, "ANTHROPIC_API_KEY", "")
#%%
get(ENV, "OPENAI_API_KEY", "")

#%%
get(ENV, "PATH", "")

#%%


#%%

using AISH: extract_code
extract_code("```sh\nls\n```")
# ann = ai"Capital of france"
#%%
ann.content
#%%
using AIHelpMe
# aihelp("What is the string field of AIMessage?")
aihelp("How do I specify the for aigenerate what model to use? I would want to use Sonnet 3.5 model? What is its name?")
#%%
conversation = [
  UserMessage("Are you here?")
]
aigenerate(conversation, model="gpt4t")
#%%
PT = PromptingTools

