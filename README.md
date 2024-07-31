
# AISH.jl

AI SH to do EVERYTHING on PC


AISH.jl (AI Shell) is a Julia package that provides an interactive AI-powered command-line interface for assisting users with system tasks using shell commands.

## Features

- AI-powered shell assistant
- Multi-model support
- Conversation memory
- Error handling
- Dynamic system prompts
- Shell command execution
- Conversation logging

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
- RAG (EasyRAG)
- STREAMING
- GUI (AIApp)
- VOICE INPUT (should be in the AIApp)
- FINE TUNEING BENCHMARKING
- If you don't want to WRITE out the entire file THEN find a new way of diff! So we should create a sort of patch... or another diff view which would be possible to be used with meld!
- LIVE modification... So it could even eval the running function.... THIS IS ONLY GOOD IF WE WANT TO DEVELOP ITSELF... BUT nice feature... :D
✓ Multi SH can be handled
✓ Update the SYSTEM_PROMPT AS THE FILES CHANGE
✓ DIFF view!! VERY narrow version... so literally the characters those changes... Also using colors. COMPARE!!
✓ error management... Claude is down... then...
✓ BENCHMARKING
✓ READLINE repair like you did before with REPL!
✓ modify the cat > ... to meld...
✓ configuring the project throught command line arguments: PROJECT_PATH
✓ project file search improvement.
✓ default arg to be the project path...
✓ the sshresult is somehow duplicating...
-✓ Thinking should be an interactive line that shows basically progress... But in the end it disappear
✓ Multiline input is necessary....
✓ cd into the project path... so everything will be realtive to that! :D
✓ empty run
✓ ctrl + c handling...
✓ multilanguage support
- layered AI... so we would have one that produce sh blocks but the internal core should talk with code blocks later on. 
- simplify the answer... shorter... filter sentences should be minimized!
- Canceling a query should be possible somehow! Do we have "stop" API? example: https://api.claude.ai/api/organizations/d9192fb1-1546-491e-89f2-d3432c9695d2/chat_conversations/f2f779eb-49c5-4605-b8a5-009cdb88fe20/stop_response

-Default talks like:
  - What should I know about this solution...
  - format the code... improve spacing
  - simplify the code...without changing the behaviour
  - take all the using and import into the include.jl main file.

THE DEFAULT TALKS IS BASICALLY C O T!... OMG :D OMG omg... omg...
in the end it all breaks down to "chains with confirmations by the US!"
Finding what "stable state can we manually automatically validate" and traveling from stable states to stable states...

- work till the task isn't ready CoT
problem ->
  - solve
  - how to run
  - how to test
  - did it succeed?
  - jump to 1.
- multilanguage support. So for now Julia... next Javascript.. next python... next DOCS for it... so it will be up for the community!



- AI assistent functionalities
  - mail read
  - organizing calendar
  - organizing TODO list
  - messenger communication automation
  - website/internet search and surfing

- we need custom benchmark examples...
- - like modifying the code to achieve a state...
- - test cases should be automatically generated on codebases. If it reach the appropriate state in 1 prompt or not. Also we should modify the prompt till it would be achievable by human. 
- - sh code modification and code validation... 
- - also maybe CoT... so it could solve in certain steps. We would accept longer resolution (Feature: CoT is required for this) 

# Why Julia?

Because julia is the most descriptive, simple language while keeping literally C/C++ speed. This means drastically faster development and understandable code. Also it has crazy stuffs starting with Revise and many more, (julia-awesome overview will be linked for extrem productivity)

Also for humans and for AI the context length is limited, this way we can get always on the top for both "user". :D

