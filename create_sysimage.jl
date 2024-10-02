using PackageCompiler
using AISH

create_sysimage(
    [
        "ArgParse", "PrecompileTools", 
        "Pkg", "JSON3", "Random", "ExpressionExplorer", "UUIDs", "JuliaSyntax", "HTTP", "SHA", "REPL", "LinearAlgebra", "Snowball", "DataStructures", "SparseArrays", "ProgressMeter", "Anthropic", "Dates", "JLD2", "Parameters", 
        "PromptingTools", "BoilerplateCvikli"
    ],
    sysimage_path="aish_sysimage.so",
    precompile_execution_file="test/playground/precompile_aish.jl"
)


