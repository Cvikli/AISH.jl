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
worktree_path = "./cpyyyss"
branch_name = "TODO-8-tokennn"

init_repo_and_create_worktree(main_repo_path, worktree_path, branch_name)

#%%

repo = LibGit2.GitRepo(main_repo_path)
head_ref = LibGit2.head(repo)
if LibGit2.isattached(repo)
    LibGit2.shortname(head_ref)
else
    "HEAD detached at $(LibGit2.short(LibGit2.GitHash(head_ref)))"
end
#%%
typeof(LibGit2.shortname(head_ref))
#%%
head_oid = LibGit2.head_oid(repo)

#%%
pwd()
#%%
main_repo_path
#%%

LibGit2.add!(repo, ".")  # Stages new and modified files
		
index = LibGit2.GitIndex(repo)

tree_id = LibGit2.write_tree!(index)
parent_ids = LibGit2.GitHash[]
head_commit = LibGit2.head(repo)  # will this error if no head? maybe I should listen to the Claude Sonnet 3.5? :D
push!(parent_ids, LibGit2.GitHash(head_commit))

sig = LibGit2.Signature("todo4.ai", "tracker@todo4.ai")

commit_id = LibGit2.commit(repo, message; committer=sig, tree_id=tree_id, parent_ids=parent_ids)
#%%
repo = LibGit2.GitRepo(main_repo_path)
LibGit2.add!(  repo, ".")
index = LibGit2.GitIndex(repo)
message="ALL donefefwefe"
tree_id = LibGit2.write_tree!(index)
tree = LibGit2.GitTree(repo, tree_id)

# Get the current HEAD as parent
parent_commit = LibGit2.head(repo)

parent_ids = LibGit2.GitHash[]  
head_commit = LibGit2.GitCommit(repo, "HEAD")
push!(parent_ids, LibGit2.GitHash(head_commit))
# Create the commit
sig = LibGit2.Signature(repo)  # Get default signature from repo config
commit_id = LibGit2.commit(repo, message, tree_id=tree_id, parent_ids=parent_ids, author=sig, committer=sig)

        
#%%
project_path = "/../to/your/project/../../../folder"
last_folder = normpath(project_path)
#%%
basename(ans)
#%%
last_folder = basename(abspath(project_path))
#%%
(LibGit2.head_oid(LibGit2.GitRepo(main_repo_path)))
#%%
head_commit = LibGit2.peel(LibGit2.GitCommit, head_ref)
@show LibGit2.GitHash(head_commit)
short_sha = LibGit2.shortname(LibGit2.GitHash(head_commit))
#%%
typeof(head_ref)

#%%
using Dates
main_branch = "master"
function get_branch_history(repo_path::String)
    repo = LibGit2.GitRepo(repo_path)
        # Get the current branch name
    branch = LibGit2.lookup_branch(repo, branch_name)
    @show branch
    main = LibGit2.lookup_branch(repo, main_branch)
    
    branch_commit = LibGit2.peel(LibGit2.GitCommit, branch)
    main_commit   = LibGit2.peel(LibGit2.GitCommit, main)
    branch_oid = LibGit2.GitHash(branch_commit)
    main_oid   = LibGit2.GitHash(main_commit)
    println("Commit of branch '$branch_name': ", branch_commit)
    println("Commit of branch '$branch_name': ", branch_oid)
    # Get the commit history
    history = LibGit2.GitRevWalker(repo)
    LibGit2.push!(history, LibGit2.GitHash(LibGit2.head(repo)))
    

    println("Commit history for branch '$branch_name':")
    for commit in history
        @show commit
        commit_obj = LibGit2.GitCommit(repo, LibGit2.GitHash(commit))
        println("Message: $(LibGit2.message(commit_obj))")

        author = LibGit2.author(commit_obj)
        println("Author: $(author.name) <$(author.email)>")
        println("Author Date: $(Dates.unix2datetime(author.time))")

        committer = LibGit2.committer(commit_obj)
        println("Committer: $(committer.name) <$(committer.email)>")
        println("Commit Date: $(Dates.unix2datetime(committer.time))")
        commit_str = string(commit)
        main_str = string(main_oid)
        @show main_str
        if LibGit2.is_ancestor_of(commit_str, main_str, repo)
            branch_point = commit
            break
        end
        # author = LibGit2.author(commit)
        # println("$(LibGit2.Oid(commit)) - $(author.name) - $(author.time) - $(LibGit2.message(commit))")
    end
end

# function count_branches_started_here(repo_path::String)
#     repo = LibGit2.GitRepo(repo_path)
#     try
#         current_commit = LibGit2.head_oid(repo)
        
#         # We'll use a system call to get all branches that contain the current commit
#         branches = readchomp(`git -C $repo_path branch --all --contains $(string(current_commit))`)
#         branch_list = split(branches, '\n')
        
#         # Count branches, excluding the current one
#         count = length(branch_list) - 1
        
#         println("Number of branches started from the current commit: $count")
#         println("Branches: ", join(branch_list, ", "))
#     finally
#         close(repo)
#     end
# end

cd(main_repo_path) do
get_branch_history(worktree_path)

# Count branches started from the current commit in the worktree
# count_branches_started_here(worktree_path)
end

#%%
c7cc06d