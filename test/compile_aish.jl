using PackageCompiler
using AISH

create_sysimage(
    [:PromptingTools, :ArgParse, :Dates, :UUIDs],
    sysimage_path="aish_sysimage.so",
    precompile_execution_file="test/precompile_aish.jl"
)

# julia test/compile_aish.jl -p=. --message "say yes" 
# julia -Jaish_sysimage.so ./test/main.jl.jl