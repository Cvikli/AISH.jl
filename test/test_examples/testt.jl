
using EasyContext
ctx_question="do you see packages that has networking server stuffs in it? http?"
julia_pkgs        = EasyContext.JuliaLoader()
julia_ctx         = EasyContext.Context()
jl_age!           = EasyContext.AgeTracker()
jl_changes        = EasyContext.ChangeTracker()
jl_simi_filter    = EasyContext.create_combined_index_builder(top_k=30)
reranker_filterer = EasyContext.ReduceRankGPTReranker(batch_size=30, model="gpt4om")

file_chunks = julia_pkgs(EasyContext.SourceChunker())
@show file_chunks
if isempty(file_chunks)
	""
else
	# entr_tracker()
	file_chunks_selected = jl_simi_filter(file_chunks, ctx_question)
	file_chunks_reranked = reranker_filterer(file_chunks_selected, ctx_question)
	merged_file_chunks   = julia_ctx(file_chunks_reranked)
	jl_age!(merged_file_chunks, max_history=5)
	state, scr_content   = jl_changes(merged_file_chunks)
	EasyContext.julia_ctx_2_string(state, scr_content)
end


#%%
using EasyContext: JuliaLoader
using EasyContext: SourceChunker
using EasyContext: cache_key
using SHA 

function fn(loader, args...)
	@show args
	key = cache_key(loader, args...)
	@show key
end
fn(JuliaLoader(), SourceChunker())
cache_key(JuliaLoader(), SourceChunker())
#%%
using EasyContext: JuliaLoader
using EasyContext: SourceChunker
using EasyContext: cache_key

using DataStructures
using EasyContext: CachedLoader
CachedLoader(loader=JuliaLoader(),memory=Dict{String,OrderedDict{String,String}}())(SourceChunker())

#%%
6d29165b79575b4e433503a474e87b33a90476664e462b94aae0610f225de6d3
#%%
using LibGit2
# const TODO4AI_Signature::LibGit2.Signature = LibGit2.Signature("todo4.ai", "tracker@todo4.ai")
init_git(path::String, forcegit = true) = begin
	if forcegit
		println("Initializing new Git repository at $path")
		repo = LibGit2.init(path)

		idx = LibGit2.GitIndex(repo)
		tree_id = LibGit2.write_tree!(idx)
  
		LibGit2.commit(repo, "Initial commit"; committer=TODO4AI_Signature, tree_id=tree_id)
	else 
		@assert false "yeah this end is unsupported now :D.. TODO"
		return nothing
	end
end 
init_git("./test/cpyy")

#%%

ctx_test = "    <TestCode>\n\t\t@testitem \"027_flip_case.jl\" tags=[:HumanEval] begin\n\n    include(joinpath(ENV[\"GENERATION_DIR\"], \"027_flip_case.jl\"))\n\n    @test flip_case(\"\") == \"\"\n    @test flip_case(\"Hello!\") == \"hELLO!\"\n    @test flip_case(\"These violent delights have violent ends\") == \"tHESE VIOLENT DELIGHTS HAVE VIOLENT ENDS\"\nend\n    </TestCode>\n    <TestResults sh=\"`bash -c julia 9d4126ba-aac9-4bf6-8002-06b91d1f4312`\">\n\t\texit_code=0\n    </TestResults>\n    "

println(ctx_test)
#%%
println("Hello, World!")

