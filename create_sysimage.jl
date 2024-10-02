
using PackageCompiler
using Pkg

included_pkgs = [
    "ArgParse", "PrecompileTools", 
    "Pkg", 
    "JSON3", "Random", "ExpressionExplorer", "UUIDs", "JuliaSyntax", 
    "HTTP", "SHA", 
    "REPL", "LinearAlgebra", 
    "Snowball", "DataStructures", "SparseArrays", "ProgressMeter", "Dates", "JLD2", "Parameters", 
    "PromptingTools", 
    "BoilerplateCvikli"
]

# Ensure all packages are installed (without specific versions)
Pkg.add(included_pkgs)

create_sysimage(
    included_pkgs,
    sysimage_path="aish_sysimage.so",
    precompile_execution_file="test/playground/precompile_aish.jl"
)

# julia create_sysimage.jl 
# julia --project=../../EasyContext create_sysimage.jl 

