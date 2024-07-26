
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
- RAG
- STREAMING
- Multi SH run
- Update the SYSTEM_PROMPT AS THE FILES CHANGE
- DIFF view!! VERY narrow version... so literally the characters those changes... Also using colors. COMPARE!!
- LIVE modification... So it could even eval the running function.... THIS IS ONLY GOOD IF WE WANT TO DEVELOP ITSELF... BUT nice feature... :D
- error management... Claude is down... then...
- BENCHMARKING
- FINE TUNEING
- GUI
- VOICE INPUT
- READLINE repair like you did before with REPL!
- modify the cat > ... to meld...
- configuring the project throught command line arguments: PROJECT_PATH
- If you don't want to WRITE out the entire file THEN find a new way of diff! So we should create a sort of patch... or another diff view which would be possible to be used with meld!


Default talks like:
- What should I know about this solution... 
- format the code... improve spacing
- simplify the code...without changing the behaviour
- take all the using and import into the include.jl main file. 


- AI assistent functionalities
  - mail read
  - organizing calendar
  - organizing TODO list
  - messenger communication automation
  - website/internet search and surfing


- project file search improvement.



