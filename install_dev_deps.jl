using Pkg

"""
Install all required dependencies for AISH.jl in development mode.
The script clones repositories if needed and adds them as dev dependencies.
"""
function install_dev_deps()
    repos = [
        ("git@github.com:Sixzero/EasyContext.jl.git", "EasyContext.jl"),
        ("git@github.com:Sixzero/EasyRAGStore.jl.git", "EasyRAGStore.jl"),
        ("git@github.com:SixZero/StreamCallbacksExt.jl.git", "StreamCallbacksExt.jl"),
        ("git@github.com:sixzero/LLMRateLimiters.jl.git", "LLMRateLimiters.jl")
    ]
    
    # Create base directory based on OS
    base_path = Sys.iswindows() ? "c:\\repo" : expanduser("~/repo")
    mkpath(base_path)
    
    # Update existing repos in parallel
    existing_repos = filter(((_, name),) -> isdir(joinpath(base_path, name)), repos)
    if !isempty(existing_repos)
        @info "Updating existing repositories..."
        asyncmap(existing_repos) do (_, name)
            dir_path = joinpath(base_path, name)
            cd(dir_path) do
                run(`git pull --rebase`)
            end
            @info "Updated $name"
        end
    end
    
    # Clone missing repos
    missing_repos = filter(((_, name),) -> !isdir(joinpath(base_path, name)), repos)
    for (url, name) in missing_repos
        dir_path = joinpath(base_path, name)
        @info "Cloning $name..."
        run(`git clone $url $dir_path`)
    end
    
    # Add all repos as dev dependencies
    for (_, name) in repos
        dir_path = joinpath(base_path, name)
        @info "Adding $name in dev mode..."
        Pkg.develop(path=dir_path)
    end
    
    @info "All dependencies have been set up successfully!"
end

# Run installation
install_dev_deps()