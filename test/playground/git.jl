
using LibGit2
using Dates

# Open the existing repository
repo = LibGit2.GitRepo(".")

# Check if there are any commits
empty_repo = isempty(LibGit2.GitRevWalker(repo))

# If the repo is empty, make an initial commit
if empty_repo
    # Create a dummy file for the initial commit
    open("initial_file.txt", "w") do file
        write(file, "Initial commit")
    end
    LibGit2.add!(repo, "initial_file.txt")
    LibGit2.commit(repo, "Initial commit")
    println("Made initial commit")
end

# Get the current branch name
current_branch = LibGit2.branch(repo)

# Create a new branch
new_branch = "new-feature3"
head_commit = LibGit2.GitCommit(repo, "HEAD")
LibGit2.create_branch(repo, new_branch, head_commit)

# Switch to the new branch
LibGit2.branch!(repo, new_branch)
println("Switched to new branch: $new_branch")

# Make changes and commit to the new branch
open("new_file.txt", "w") do file
    write(file, "This is a new file in the $new_branch branch")
end
LibGit2.add!(repo, "new_file.txt")
LibGit2.commit(repo, "Add new file in $new_branch branch")

# Function to display commit history
function display_commits(repo)
    walker = LibGit2.GitRevWalker(repo)
    LibGit2.push_head!(walker)

    for oid in walker
        commit = LibGit2.GitCommit(repo, oid)
        hash = string(oid)
        author = LibGit2.author(commit)
        message = LibGit2.message(commit)
        
        println("Commit: ", hash[1:7])
        println("Author: ", author.name, " <", author.email, ">")
        println("Date:   ", Dates.unix2datetime(author.time))
        println("    ", message)
        println()
    end
end

# Display commits in the new branch
println("Commits in '$new_branch' branch:")
display_commits(repo)

# Switch back to the original branch
LibGit2.branch!(repo, current_branch)

# Display commits in the original branch
println("\nCommits in '$current_branch' branch:")
display_commits(repo)

#%%
using LibGit2

clean_branches(paths=["."]) = begin
    for repo_path in paths
        repo = LibGit2.GitRepo(repo_path)
        @show repo
        cmd = `git -C $repo_path worktree list`
        output = read(cmd, String)
        worktree_lines = filter(!isempty, split(output, "\n"))
        @show worktree_lines
        for line in worktree_lines[2:end]
            parts = split(line)
            @show parts
            branch_name = String(parts[3][2:end-1])
            @show branch_name
            wt_path = parts[1]
            @show wt_path
            
            # Remove the worktree
            run(`git -C $repo_path worktree remove $wt_path`)
            
            # Try to get and delete the associated branch
            branch_ref = LibGit2.lookup_branch(repo, branch_name) # "unnamed-branch"
            if branch_ref !== nothing
                @show branch_ref
                LibGit2.delete_branch(branch_ref)
            end
                
        end
        # repo = LibGit2.GitRepo(repo_path)
        
        # # Get all worktrees
        # worktrees = LibGit2.worktrees(repo)
        # @show worktrees
    end
end
clean_branches()
#%%

output = read(`git branch -m unnamed-branch new_name`, String)

