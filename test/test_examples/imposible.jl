
using EasyContext: JuliaLoader
using EasyContext: SourceChunker
using EasyContext: cache_key

using DataStructures
using EasyContext: CachedLoader
using EasyContext: create_voyage_embedder, create_combined_index_builder, get_index
# CachedLoader(loader=JuliaLoader(),memory=Dict{String,OrderedDict{String,String}}())(SourceChunker())


@time voyage_embedder = create_voyage_embedder(model="voyage-code-2")
@time jl_simi_filter = create_combined_index_builder(voyage_embedder; top_k=120)
@time jl_pkg_index = get_index(jl_simi_filter, CachedLoader(loader=JuliaLoader(),memory=Dict{String,OrderedDict{String,String}}())(SourceChunker()))
;
