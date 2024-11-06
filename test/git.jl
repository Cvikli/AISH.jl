

git worktree remove ~/testworktree 
git worktree prune   

#%%

using LibGit2

clean_branches(;paths=["."], branches=[], force=false) = begin
    @assert force==false || (force==true && !isempty(branches)) "Be careful to run this command with no specified branch but using FORCE delete! As it delete nearly every worktree. So only the real branches which aren't worktree stays..."
    @show pwd()
    for repo_path in paths
        @show repo_path
        cd(repo_path) do
            repo = LibGit2.GitRepo(repo_path)
            @show repo
            cmd = `git -C $repo_path worktree list`
            output = read(cmd, String)
            worktree_lines = filter(!isempty, split(output, "\n"))
            for line in worktree_lines[2:end]
                parts = split(line)
                branch_name = String(parts[3][2:end-1])
                @show branch_name
                # !startswith(branch_name, "unnamed-branch") && continue
                !isempty(branches) && !(branch_name in branches) && continue
                wt_path = parts[1]
                forcestr = force ? "--force" : ""
                # Remove the worktree
                try
                    run(`git -C $repo_path worktree remove $forcestr $wt_path`) 
        
                    
                    # Try to get and delete the associated branch
                    branch_ref = LibGit2.lookup_branch(repo, branch_name) # "unnamed-branch"
                    if branch_ref !== nothing
                        @show branch_ref
                        LibGit2.delete_branch(branch_ref)
                    end
                catch e    
                    @error "Failed to remove worktree" exception=(e, catch_backtrace())
                end
                
            end
            # repo = LibGit2.GitRepo(repo_path)
            
            # # Get all worktrees
            # worktrees = LibGit2.worktrees(repo)
            # @show worktrees
        end
    end
end
clean_branches(paths=["."],branches=["apply-changes-to-file-with-streaming-ai-generate"], force=true)

#%%
# split(read(`ls`, String),"\n")
# #%%
# cd("EasyContext.jl")
# #%%
# cd("../")


#%%
using EasyContext: GitTracker, merge_git

base_path="/home/hm/repo/AIStuff/AISH.jl/conversations/01JBYQ9YH5JKJ3YYPX"
# tracker = GitTracker([WorkTree(LibGit2.GitRepo(base_path))], "")

merge_git(GitTracker(base_path))

#%%
using LibGit2
path="/home/hm/repo/AIStuff/AISH.jl/conversations/01JBYE82FNVB1VNJHC/EasyContext.jl"
repo = LibGit2.GitRepo(path)
LibGit2.add!(repo, ".")        # Stages new and modified files

index = LibGit2.GitIndex(repo)

tree_id = LibGit2.write_tree!(index)
parent_ids = LibGit2.GitHash[]
head_commit = LibGit2.head(repo)    # will this error if no head? maybe I should listen to the Claude Sonnet 3.5? :D
push!(parent_ids, LibGit2.GitHash(head_commit))

commit_id = LibGit2.commit(repo, "commit_msg"; tree_id=tree_id, parent_ids=parent_ids)



