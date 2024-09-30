using PackageCompiler
using AISH

create_app(".", "aish_executable";
    precompile_execution_file="test/playground/precompile_aish.jl",
    include_transitive_dependencies=true,
    filter_stdlibs=false,
    force=true,
    incremental=false
)
