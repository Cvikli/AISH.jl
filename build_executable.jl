using PackageCompiler
using AISH

create_app(".", "aish_executable";
    precompile_execution_file="test/precompile_aish.jl",
    include_transitive_dependencies=true,
    filter_stdlibs=true,
    force=true
)
