
using EasyContext: JuliaLoader
using EasyContext: SourceChunker
using EasyContext: cache_key

using DataStructures
using EasyContext: CachedLoader
CachedLoader(loader=JuliaLoader(),memory=Dict{String,OrderedDict{String,String}}())(SourceChunker())

