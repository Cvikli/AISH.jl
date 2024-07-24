using RelevanceStacktrace

using Revise
using AISH: start_conversation, initialize_ai_state

ai_state = initialize_ai_state()
;
# start_conversation(ai_state)
#%%

start_conversation(ai_state, resume=false)
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
using Term.Prompts

prompt = Prompt("Simple, right?");
prompt |> ask

#%%
using REPL.Terminals
function clear_line()
    # terminal = Terminals.TTYTerminal("", stdin, stdout, stderr)
    Terminals.clear_line(Base.active_repl.t)
end

#%%
readline(Base.active_repl.t; keep=true)
#%%
asdf1 = clear_line()
asdf2 = readline()
asdf3 = clear_line()
asdf4 = readline()
asdf3 = clear_line()
asdf5 = readline()
asdf3 = clear_line()
;
#%%
@show asdf1
@show asdf2
@show asdf3
@show asdf4
@show asdf5
@show asdf6
#%%
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

