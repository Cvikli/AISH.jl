using LibGit2

function init_repo_and_create_worktree(main_repo_path::String, worktree_path::String, branch_name::String)

    cd(main_repo_path) do
        # Initialize the main repository if it doesn't exist
        if !isdir(joinpath(".", ".git"))
            println("Initializing new Git repository at $main_repo_path")
            repo = LibGit2.init(".")
            
            # Create an initial commit
            LibGit2.commit(repo, "Initial commit")
        else
            repo = LibGit2.GitRepo(".")
        end
        @show repo
        @show fieldnames(GitRepo)
        @show repo.ptr
        # return

            # Check if the branch exists
        if LibGit2.lookup_branch(repo, branch_name) === nothing
            # If the branch doesn't exist, create it
            head_oid = LibGit2.head_oid(repo)
            LibGit2.create_branch(repo, branch_name, LibGit2.GitCommit(repo, head_oid))
            println("Created new branch: $branch_name")
        end
        # Create the worktree
        run(`git worktree add $worktree_path $branch_name`)
        
        println("Worktree created successfully at $worktree_path for branch $branch_name")
    end
end

# Usage example
main_repo_path = "./test/playground/test"
worktree_path = "./cpyyy"
branch_name = "TODO-8-tokenn"

init_repo_and_create_worktree(main_repo_path, worktree_path, branch_name)


#%%

function get_branch_history(repo_path::String)
    repo = LibGit2.GitRepo(repo_path)
    try
        # Get the current branch name
        head_ref = LibGit2.head(repo)
        branch_name = LibGit2.shortname(head_ref)
        
        # Get the commit history
        history = LibGit2.GitRevWalker(repo)
        LibGit2.push!(history, LibGit2.GitHash(LibGit2.head(repo)))
        
        println("Commit history for branch '$branch_name':")
        for commit in history
            @show commit
            author = LibGit2.author(commit)
            println("$(LibGit2.Oid(commit)) - $(author.name) - $(author.time) - $(LibGit2.message(commit))")
        end
    finally
        close(repo)
    end
end

function count_branches_started_here(repo_path::String)
    repo = LibGit2.GitRepo(repo_path)
    try
        current_commit = LibGit2.head_oid(repo)
        
        # We'll use a system call to get all branches that contain the current commit
        branches = readchomp(`git -C $repo_path branch --all --contains $(string(current_commit))`)
        branch_list = split(branches, '\n')
        
        # Count branches, excluding the current one
        count = length(branch_list) - 1
        
        println("Number of branches started from the current commit: $count")
        println("Branches: ", join(branch_list, ", "))
    finally
        close(repo)
    end
end

cd(main_repo_path) do
get_branch_history(worktree_path)

# Count branches started from the current commit in the worktree
count_branches_started_here(worktree_path)
end