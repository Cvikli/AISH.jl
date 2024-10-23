
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
#%%

output = read(`git branch -m unnamed-branch new_name`, String)

