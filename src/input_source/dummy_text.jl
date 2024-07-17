speeches = [
    "Hey Vex, can you tell me the weather?",
    "I wonder if Vex would know the answer to this question.",
    "Vex please calculate 15 times 7",
    "This has nothing to do with Vex at all.",
    "Vex, what's the capital of France?",
    "I asked Vex yesterday about the stock market."
]

function get_random_speech()::String
    return rand(speeches)
end
