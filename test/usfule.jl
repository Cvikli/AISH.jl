git worktree remove ~/testworktree 
git worktree prune   

#%%

using LibGit2

clean_branches(;paths=["."], branches=[], force=false) = begin
    @assert force==false || !(force==true && !isempty(branches)) "Be careful to run this command with no specified branch but using FORCE delete! As it delete nearly every worktree. So only the real branches which aren't worktree stays..."
    for repo_path in paths
        cd(repo_path) do
            @show "3232"
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
clean_branches(branches=[], force=false)
