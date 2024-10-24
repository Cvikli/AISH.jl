using Revise
using RelevanceStacktrace
using AISH: start

start("greet me with hi please", project_paths=["."])
# start("his implementation efficiently computes the n-th element of the fib4 sequence without using recursion. It uses a loop to iterate through the sequence, updating four variables that represent the last four numbers in the sequence. The function also handles the base cases for n = 0, 1, 2, and 3 as specified in the problem description.", project_paths=["."], loop=true)
#%%

message ="""
    remove_duplicates(numbers::Vector{Int})::Vector{Int}

From a list of integers, remove all elements that occur more than once. Keep
order of elements left the same as in the input.

# Examples

```jldoctest
julia> remove_duplicates([1, 2, 3, 2, 4])
3-element Vector{Int64}:
 1
 3
 4
```
"""
ENV["GENERATION_DIR"] = "test/humaneval"
start(message, loop=true, no_confirm=true, test_cases="""using ReTestItems

@testitem "026_remove_duplicates.jl" tags=[:HumanEval] begin

    include(joinpath($(ENV["GENERATION_DIR"]), "026_remove_duplicates.jl"))

    @test remove_duplicates(Int[]) == []
    @test remove_duplicates([1, 2, 3, 4]) == [1, 2, 3, 4]
    @test remove_duplicates([1, 2, 3, 2, 4, 3, 5]) == [1, 4, 5]
end""", test_filepath="test/humaneval/026_remove_duplicates.jl")
# start("do you see packages that has networking server stuffs in it?", project_paths=["."])
# start("do we have new flag for building executeable that generate smaller code, please modify the file appropriately", project_paths=["."])



#%%
using LibGit2
using EasyContext: merge, GitTracker, Branch
path="/home/hm/repo/AIStuff/AISH.jl/conversations/01JAZRNPBBH7Z3C2VE/AISH.jl"
original_path="/home/hm/repo/AIStuff/AISH.jl"

orig_repo = LibGit2.GitRepo(original_path)
conv_repo = LibGit2.GitRepo(path)
@show LibGit2.workdir(conv_repo)
g = GitTracker(Branch[Branch(LibGit2.head_oid(orig_repo), orig_repo, conv_repo, path, "greet-me-with-hi")],"greettt")

#%%
merge(g)

#%%
merge_git(repo_path::String, branch::String, commit_msg::String) = begin
	cd(repo_path) do
		run(`git stash save "Temp stash before $(branch)"`)
		merge_result = read(`git merge $(branch) --no-ff -m "$(commit_msg)"`, String)
		if occursin("CONFLICT", merge_result) || occursin("error:", merge_result)
            @warn ("Merge conflict detected: $merge_result")
		else
			pop_result = read(`git stash pop`, String)
			if occursin("CONFLICT", pop_result) || occursin("error:", pop_result)
				@warn ("Stash pop conflict detected: $pop_result")
			end
		end
	end
end
# path="/home/hm/repo/AIStuff/AISH.jl/conversations/01JAZRNPBBH7Z3C2VE/AISH.jl"
original_path="/home/master/repo/AIStuff/AISH.jl"
branch="greet-user"
msg="Is it testabl"
merge_git(original_path, branch, msg)