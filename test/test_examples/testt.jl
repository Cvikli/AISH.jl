
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

