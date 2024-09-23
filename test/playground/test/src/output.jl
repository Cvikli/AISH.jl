using OutputCollectors
using OutputCollectors: collect_output

script="for i in {1..10}; do echo \$i; sleep 1; done"


output = IOBuffer()
cmd, oc = collect_output(`sh ./long.sh`, [output])
wait(oc)
@show String(take!(output))

# String(take!(output))
# "1\n2\n3\n4\n"