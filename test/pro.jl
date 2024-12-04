using Revise
# using EasyContext: EasyContextCreatorV4
using AISH: start
using AISH: main
using AISH: SRWorkFlow
using AISH: STDFlow
using RelevanceStacktrace

start("correct mistake in the file that is included in the config.jl", workflow=STDFlow, project_paths=".")



