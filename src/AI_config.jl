const ChatSH::String = "Orion"
const ainame::String = lowercase(ChatSH)
# AI name have to be short, transcriptable not ordinary common word.

const DATE_FORMAT_REGEX = r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:z|Z)?"
const DATE_FORMAT::String = "yyyy-mm-ddTHH:MM:SS.sssZ"

const MSG_FORMAT::Regex = r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+Z)?) \[(\w+), id: ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}), in: (\d+), out: (\d+), cached: (\d+), cache_read: (\d+), price: ([\d.]+), elapsed: ([\d.]+)\]: (.+)"s

const CONVERSATION_DIR = joinpath(@__DIR__, "..", "conversations")
const CONVERSATION_FILE_REGEX = Regex("^($(DATE_FORMAT_REGEX.pattern))_(?<sent>.*)_(?<id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\\.log\$")
mkpath(CONVERSATION_DIR)

get_system() = strip(read(`uname -a`, String))
get_shell() = strip(read(`$(ENV["SHELL"]) --version`, String))

