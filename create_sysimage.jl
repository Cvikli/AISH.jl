using PackageCompiler
using AISH

create_sysimage(
    ["Dates", "UUIDs", "DataStructures", "PromptingTools", "BoilerplateCvikli", "ArgParse", "REPL", "Random", "HTTP"],
    sysimage_path="aish_sysimage.so",
    precompile_execution_file="test/precompile_aish.jl"
)


