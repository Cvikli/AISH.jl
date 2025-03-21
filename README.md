
# AISH.jl

![matrix](https://github.com/user-attachments/assets/f90a1d9c-dfe2-4a41-a5a7-c53d8aefa4d4)

Everything is a transformation... You can describe every workflow soon...

THE PACEKAGE is in an extremely experimental, it works for me but... no real docs yet!

AI SH to do EVERYTHING on PC

AISH provide a new way of coding. Basically we switch from 100% code file editing to 10% codefile editing and 90% codeblock editing from the AISH. 

Vscode extension will come. 

AISH.jl (AI Shell) is a Julia package that provides an interactive AI-powered command-line interface for assisting users with system tasks using shell commands.

# USAGE
Run in any folder:
```sh
julia --banner=no -i -e 'using AISH; AISH.airepl(auto_switch=true)'
```
Also see help by typing `-h` in the AISH REPL... you can set fairly many options there to speed up development.

DEPRECATED: GUI: [AISHApp](https://github.com/Cvikli/AISHApp)
DEPRECATED: Backend server for the GUI: [AISHServer](https://github.com/Cvikli/AISHServer)

Other webversion is coming soon...

It is actually ChatSH but a little bit rethinked version!

WARNING: the project in experimental state! APIs can change if we see better patterns as we are researching for the simplest LLM SH system yet. 

<center>Of course it can do a lot more then this! Basically it wrote most of his own codebase</center>

## Features

- AI-powered shell assistant
- Multi-model support
- Conversation memory
- Error handling
- Dynamic system prompts
- Shell command execution
- Conversation logging

## Version Control Integration

AISH.jl supports git integration through a detached development workspace feature:

- When `detached_git_dev=true` (default), AISH creates separate git worktrees for each project, allowing version control without affecting the original repository.
- Changes are tracked and can be merged back to the original repository using the MERGE command.
- Disable with `detached_git_dev=false` if you prefer to work directly in the original workspace without version control.

Example usage:
```julia
# With version control (default)
AISH.start("my question", project_paths=["path/to/project"])

# Without version control
AISH.start("my question", project_paths=["path/to/project"], detached_git_dev=false)
```

## Limitation estimation (Sonnet 3.5)
- On very basic cases it works around like 90-99% of the times. 
- Sometimes it forces like 3-4 different solutions and somehow feels like it stuck with old API document and that is the cause of the issue. 
- Sometimes it is too hard to explain a very complex data management behind when it just cannot create the best solution for you.
- Also lot of time it writes stuff that does somehow similar functionality than some part of a code or it forget to use a state of a variable which is not really related but actually will hold useful information in that stage of the code which could reduce some calculation, in these cases we have to point out to use the values in those storages.
- It sometimes too precise and even put the type annotation in the functions args which isn't always a good pattern, so that should be somehow ordered to be more lazy. 
- Also it writes a little lengthy code and then we have to order it to simplify it. It simplify codes EXTREMLY well but make sure it doesn't change the functionality when it simplifies it (also you can order it to keep the same functionality when simplifing).
- Refactoring have to be one by one as too big refactoring won't fit into the answer and it can be problematic by time. 
- It forces pattern that are actually very good but it can overmodularize your project. It will even know it is overmodularized if you ask it and it can make it more flat if you ask. :D   
- If there are duplicated files and codes that cause the AI to lose the reight structure and the right place to modify the codebase. (So like test files... or archived folders can be dangerous)
- Files over 250 lines are not easy for the AI to edit... But lot of case it handle it with "rest of the code" and so on.
- Javascript (react) specific: if the first solution doesn't work then it starts to complicate the solution more and more which is very likely doesn't really improve the code. In the end it can go to debug the code which most of the time help him to reach a good solution.
- Javascript (react) specific: if it goes to wrong direction, often it starts to create error handlings and more advanced version of the specified function.
- Streaming has "draft" data and "final" data and it manages it very poorly. Most of the time I had to finish these kind of work manually. Maybe someone has to prompt these more accurately to make sure to don't append draft values to the string endlessly. 

## Installation
You will need a diff view for AI proposed diffs. GUI diff views supported:
- `meld` available on most OS
- [`monaco-meld`](https://github.com/Sixzero/monaco-meld) electron/web based (AISH developed) diff view (recommended)

```julia
] 
add https://github.com/Cvikli/AISH.jl
```


This will start an interactive session where you can communicate with the AI assistant.

## Configuration

The project uses a configuration file (`src/prompt.jl`) to set up various parameters:

- `ChatSH`: The name of the AI assistant (default: "Orion")
- `SYSTEM_PROMPT`: The initial system prompt for the AI

You can modify these settings to customize the behavior of AISH.jl.

## Project Structure

- `src/`: Contains the main source code
  - `AISH.jl`: Main module file
  - `AIstate.jl`: AI state structure
  - `AI_config.jl`+`AI_prompt.jl`: Configurations
  - `process_query.jl`: Handles processing of user queries
  - `includes.jl`: Manages file inclusions
  - `error_managers/`: Error handling utilities
  - `benchmarking/`: Benchmarking tools
- `conversations/`: Stores conversation logs


## TODO
Lot of them is already ready... Most of them was written by the AISH itself! (Real singularity is here yeah XD Literally I have to put the features described here to the code and merge the solution)
- [ ] CODE merging LLM, that is EVEN taking into consideration that if a code is missing then it has to evaluate if that code was necessary to remove or not!
- [ ] Executeable generation
- [ ] stream the shell execution
- [ ] SHELL GPT version... it solve everything in the shell...
- [ ] message ID to be used instead of timestamp idenfitification + add conversation_id to it...
- [ ] SimpleContext refactor to match tha pattern of the EasyContext
  - [ ] SimpleContextNoCache create
- [ ] RAG (EasyRAG ongoing. Context + search tool)
- [ ] Self-Reflection (SR) (TEST generates the problem. Instead of us. This is the key to create SR!)
  - [ ] Define Goal -> PROBLEM & TEST
  - [ ] SOLVE(PROBLEM)
  - [ ] how to TEST (CUSTOM) defined in the Goal! 
    - [ ] did it succeed?  (get errors + results = PROBLEM) from the running version of the code. which can be immediately feed back .
    - [ ] no?  jump to SOLVE(PROBLEM)
    - [ ] yes? READY
  - [ ] problem ->
  - [ ] solve
  - [ ] how to run
  - [ ] how to test
  - [ ] did it succeed?
  - [ ] jump to "solve".
- [ ] If you don't want to WRITE out the entire file THEN find a new way of diff patch model! So we should create a sort of patch... or another diff view which would be possible to be used with meld!
- [ ] We should refactor the shell script run to be in the UserMessages
- [ ] Put the SHELL command run result into the next User Message
- [ ] The result should be abbreviated if it is more then 24 lines. Also the sh script should be abbreviated if it is more then 10 lines
- [ ] Also when we insert the shell script into the user message then we should abbreviate too long shell scripts and also abbreviate the output... so we mustn't allow more then 24 lines output... We need the first 12 and end 12 lines of the output in these case. 
- [ ] Multimodal (image + docs)
- [x] GUI (AIApp)
- [ ] FINE TUNING
  - [ ] simplify the answer... shorter... filter sentences should be minimized!
  - [ ] forbid the system to generate this many extra token in the end! 
  - [x] improve benchmark score
  - [x] forbid the AI to create ```sh_run_results blocks...
- [ ] multilanguage support. 
  - [ ] next python... 
  - [ ] next DOCS for it... so it will be up for the community!
  - [x] So for now Julia... 
  - [x] next Javascript.. 
- [x] Multiple project path handling 
  - [x] Find most common path and then replace the relative path appropriately!
- [x] Speed
  - [x] type compatibility checks!
  - [x] memory allocation checks!
  - [x] speedup! measure... improve is necessary
- [x] File tree list
- [x] Elapsed time
- [x] cost(maybe calculation?) 
- [x] token  
- [x] frontend code evaluation (execute API)
- [x] anthropic specific max token based on model (8192)
- [x] simpler server start from CMD and from julia code. 
- [x] STREAMING anthropic claude
- [x] Multi SH can be handled
- [x] Update the SYSTEM_PROMPT AS THE FILES CHANGE
- [x] DIFF view!! VERY narrow version... so literally the characters those changes... Also using colors. compare!!
- [x] error management... Claude is down... then...
- [x] BENCHMARKING basic... LLMLeaderboard
- [x] READLINE repair like you did before with REPL!
- [x] modify the cat > ... to meld...
- [x] configuring the project throught command line arguments: PROJECT_PATH
- [x] project file search improvement.
- [x] default arg to be the project path...
- [x] the sshresult is somehow duplicating...
- [x] Multiline input is necessary....
- [x] cd into the project path... so everything will be realtive to that! :D
- [x] empty run
- [x] ctrl + c handling...
- [x] multilanguage support at context creation (the comment)
- [x] resume conversation


-[ ] Default talks like:
  - [ ] What should I know about this solution...
  - [ ] format the code... improve spacing
  - [ ] simplify the code...without changing the behaviour
  - [ ] take all the using and import into the include.jl main file.

THE DEFAULT TALKS IS BASICALLY C O T!... OMG :D OMG omg... omg...
in the end it all breaks down to "chains with confirmations by the user!"
Finding what "stable state can we manually automatically validate" and traveling from stable states to stable states...




- [ ] AI assistant functionalities
  - [ ] mail read
  - [ ] organizing calendar
  - [ ] organizing TODO list
  - [ ] messenger communication automation
  - [ ] website/internet search and surfing

TODOs lost interest...
- [ ] cost(estimation!) 
- [ ] LIVE modification... So it could even eval the running function.... THIS IS ONLY GOOD IF WE WANT TO DEVELOP ITSELF... BUT nice feature... :D
- [ ] Thinking should be an interactive line that shows basically progress... But in the end it disappear

# Why Julia?

Because julia is the most descriptive, simple language while keeping literally C/C++ speed. This means drastically faster development and understandable code. Also it has crazy stuff starting with Revise and many more, (julia-awesome overview will be linked for extreme productivity)

Also for humans and for AI the context length is limited, this way we can get always on the top for both "user". :D





handle these:
```
read -q "?Continue? (y) " && meld src/api_routes.jl <(cat <<-"EOL"
# ... (existing content)

# Add this line near the top of the file, after the imports
is_ai_state_initialized() = !isnothing(ai_state)

# ... (rest of the existing content)
EOL
```




- Benchmarking




could you repair the previous conversation resume to search for the last conversation by date which is read out from the file name and then continue it. If the last conversation is a UserMessage then continue it from then.

## Contributing

Contributions to AISH.jl are welcome! Please feel free to submit issues, fork the repository and send pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

### Sponsors                                                                                          

If you feel the results and also believe opensource is key for healthy and fair world then don't forget to support our work!                                                                                                                                   
- [Github sponsor](https://github.com/sponsors/Cvikli)                                                       


