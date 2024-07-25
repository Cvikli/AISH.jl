## AISH.jl
AI SH to do EVERYTHING on PC


It is actually ChatSH but a little bit rethinked version!


## Install

pip install pydub deepgram-sdk

https://github.com/jiaaro/pydub#getting-ffmpeg-set-up
apt-get install libav-tools libavcodec-extra
####    OR    #####
apt-get install ffmpeg libavcodec-extra




# FINE TUNEING


# RAG

# STREAMING
# Multi SH run

# Update the SYSTEM_PROMPT AS THE FILES CHANGE

# DIFF view!! VERY narrow version... so literally the characters those changes... Also using colors. COMPARE!!

# LIVE modification... So it could even eval the running function.... THIS IS ONLY GOOD IF WE WANT TO DEVELOP ITSELF... BUT nice feature... :D


# What should I know about this solution... 

# Handle server overloaded which is 529 Unknown Code with retry later in some second. But please these management shouldn't appear in the process_question. So don't create try catch block over there.  Also all the other error that exist in the claude server are these: 
400 - invalid_request_error: There was an issue with the format or content of your request. We may also use this error type for other 4XX status codes not listed below.
401 - authentication_error: There’s an issue with your API key.
403 - permission_error: Your API key does not have permission to use the specified resource.
404 - not_found_error: The requested resource was not found.
413 - request_too_large: Request exceeds the maximum allowed number of bytes.
429 - rate_limit_error: Your account has hit a rate limit.
500 - api_error: An unexpected error has occurred internal to Anthropic’s systems.
529 - overloaded_error: Anthropic’s API is temporarily overloaded.


Handle server overloaded which is 529 Unknown Code with retry later in some second. . Not the anthropic_error_handler.jl is extremly bad. Please correct that safe_aigenerate function to work appropriately. Also be simple and concise. Also use this safe call in the process-query.jl

# READLINE repair like you did before with REPL!


# modify the cat > ... to meld...
# meld updated_filecontent original_file

ments le egy fájlba (a conversation mappán belül) az összes userMessage-t azonnal amint lehet. Hogy ha lefagyna a query akkor tudjuk onnan megkeresni mi volt a legutolsó 
illetve jó lenne ha lenne egy indítási mód hogy ha be lenne ragadva egy UserMessage akkor azt tudnánk egyből futtatni újra. 



# now we can remove the <SYSTEM>last_output prompting from the project. As we always insert the output after each codeblock immediately. Could you help me in this?

# default talks like: 
# format the code... improve spacing
# simplify the code...without changing the behaviour
# take all the using and import into the include.jl main file. 

# BENCHMARKING
# BENCHMARKING full scale!!

# GUI

# RAG...

# VOICE INPUT
# voice input!!