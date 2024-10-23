git worktree remove ~/testworktree 
git worktree prune   

#%%

using LibGit2

clean_branches(;paths=["."], branches=[], force=false) = begin
    for repo_path in paths
        repo = LibGit2.GitRepo(repo_path)
        @show repo
        cmd = `git -C $repo_path worktree list`
        output = read(cmd, String)
        worktree_lines = filter(!isempty, split(output, "\n"))
        for line in worktree_lines[2:end]
            parts = split(line)
            branch_name = String(parts[3][2:end-1])
            @show branch_name
						!isempty(branches) && !(branch_name in branches) && continue
            wt_path = parts[1]
            @show wt_path
            forcestr = force ? "--force" : ""
            # Remove the worktree
            run(`git -C $repo_path worktree remove $forcestr $wt_path`)
            
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
clean_branches(branches=["greet-me-with-hi"], force=true)