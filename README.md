
# AISH.jl

AI SH to do EVERYTHING on PC


AISH.jl (AI Shell) is a Julia package that provides an interactive AI-powered command-line interface for assisting users with system tasks using shell commands.

GUI: [AISHApp](https://github.com/Cvikli/AISHApp)
Backend server for the GUI: [AISHServer](https://github.com/Cvikli/AISHServer)

## DEMO


## Features

- AI-powered shell assistant
- Multi-model support
- Conversation memory
- Error handling
- Dynamic system prompts
- Shell command execution
- Conversation logging


## Limitation estimation (Sonnet 3.5)
- On very basic cases it works around like 90-99% of the times. 
- Sometimes it forces like 3-4 different solution and somehow feels like it stuck with old API document and that is the cause of the issue. 
- Sometimes it is too hard to explain a very complex data management behind when it  just cannot create the best solution for you.
- Also lot of time it writes stuff that does somehow similar functionality than some part of a code or it forget to use a state of a variable which is not really related but actually will hold useful information in that stage of the code which could reduce some calculation, in these cases we have to point out to use the values in those storages.
- It sometimes too precise and even put the type annotation in the functions args which isn't always a good pattern, so that should be somehow ordered to be more lazy. 
- Also it writes a little lengthy code and then we have to order it to simplify it. It simplify codes EXTREMLY well but make sure it doesn't change the functionality when it simplifies it (also you can order it to keep the same functionality when simplifing).
- Refactoring have to be one by one as too big refactoring won't fit into the answer and it can be problematic by time. 
- It forces pattern that are actually very good but it can overmodularize your project. It will even know it is overmodularized if you ask it and it can make it more flat if you ask. :D   
- If there are duplicated files and codes that cause the AI to lose the reight structure and the right place to modify the codebase. (So like test files... or archived folders can be dangerous)

## Installation
We use `meld`, `zsh`

```julia
using Pkg
Pkg.add("AISH")
```

For voice 2 text... TODO
<!-- pip install pydub deepgram-sdk
https://github.com/jiaaro/pydub#getting-ffmpeg-set-up
apt-get install libav-tools libavcodec-extra
####    OR    #####
apt-get install ffmpeg libavcodec-extra -->

## Usage

To start using AISH.jl, run the following commands in Julia:

```julia
using AISH

# Initialize the AI state
state = AISH.initialize_ai_state()

# Start the conversation
AISH.start_conversation(state)
```

This will start an interactive session where you can communicate with the AI assistant.

## Configuration

The project uses a configuration file (`src/config.jl`) to set up various parameters:

- `PROJECT_PATH`: The root path of your project
- `ChatSH`: The name of the AI assistant (default: "Koda")
- `SYSTEM_PROMPT`: The initial system prompt for the AI

You can modify these settings to customize the behavior of AISH.jl.

## Project Structure

- `src/`: Contains the main source code
  - `AISH.jl`: Main module file
  - `AI_struct.jl`: AI state structure
  - `config.jl`: Configuration settings
  - `process_query.jl`: Handles processing of user queries
  - `includes.jl`: Manages file inclusions
  - `error_managers/`: Error handling utilities
  - `input_source/`: Input processing utilities
  - `benchmarking/`: Benchmarking tools
- `conversation/`: Stores conversation logs

## Contributing

Contributions to AISH.jl are welcome! Please feel free to submit issues, fork the repository and send pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
## AISH.jl
AI SH to do EVERYTHING on PC


It is actually ChatSH but a little bit rethinked version!



Lot of them is already ready... Most of them was written by the AISH itself! (Real singularity is here yeah XD Literally I have to put the features described here to the code and merge the solution)
## TODO
- [ ] RAG (EasyRAG)
- [-] GUI (AIApp)
- [ ] BENCHMARKING advanced even modular...
- [ ] FINE TUNEING
- [ ] token + cost(maybe calculation?) + elapsed time registration for messages...
- [ ] If you don't want to WRITE out the entire file THEN find a new way of diff patch model! So we should create a sort of patch... or another diff view which would be possible to be used with meld!
- [ ] layered AI... so we would have one that produce sh blocks but the internal core should talk with code blocks later on. 
- [ ] simplify the answer... shorter... filter sentences should be minimized!
- [ ] forbid the system to generate this many extra token! Also the bare minimum is to forbid the AI to create ```sh_run_results blocks...
- [ ] LIVE modification... So it could even eval the running function.... THIS IS ONLY GOOD IF WE WANT TO DEVELOP ITSELF... BUT nice feature... :D
- [ ] Thinking should be an interactive line that shows basically progress... But in the end it disappear
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
- [x] multilanguage support
- [x] resume conversation

-[ ] Default talks like:
  - [ ] What should I know about this solution...
  - [ ] format the code... improve spacing
  - [ ] simplify the code...without changing the behaviour
  - [ ] take all the using and import into the include.jl main file.

THE DEFAULT TALKS IS BASICALLY C O T!... OMG :D OMG omg... omg...
in the end it all breaks down to "chains with confirmations by the US!"
Finding what "stable state can we manually automatically validate" and traveling from stable states to stable states...

- [ ] work till the task isn't ready CoT
problem ->
  - [ ] solve
  - [ ] how to run
  - [ ] how to test
  - [ ] did it succeed?
  - [ ] jump to 1.
- multilanguage support. So for now Julia... next Javascript.. next python... next DOCS for it... so it will be up for the community!



- [ ] AI assistent functionalities
  - [ ] mail read
  - [ ] organizing calendar
  - [ ] organizing TODO list
  - [ ] messenger communication automation
  - [ ] website/internet search and surfing

- [ ] we need custom benchmark examples...
  - [ ] like modifying the code to achieve a state...
  - [ ] test cases should be automatically generated on codebases. If it reach the appropriate state in 1 prompt or not. Also we should modify the prompt till it would be achievable by human. 
  - [ ] sh code modification and code validation... 
  - [ ] also maybe CoT... so it could solve in certain steps. We would accept longer resolution (Feature: CoT is required for this) 

# Why Julia?

Because julia is the most descriptive, simple language while keeping literally C/C++ speed. This means drastically faster development and understandable code. Also it has crazy stuffs starting with Revise and many more, (julia-awesome overview will be linked for extrem productivity)

Also for humans and for AI the context length is limited, this way we can get always on the top for both "user". :D





handle these:
read -q "?Continue? (y) " && meld src/api_routes.jl <(cat <<-"EOL"
# ... (existing content)

# Add this line near the top of the file, after the imports
is_ai_state_initialized() = !isnothing(ai_state)

# ... (rest of the existing content)
EOL




- Benchmarking




could you repair the previous conversation resume to search for the last conversation by date which is read out from the file name and then continue it. If the last conversation is a UserMessage then continue it from then.