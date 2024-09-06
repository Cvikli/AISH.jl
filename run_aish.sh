#!/bin/bash
julia --sysimage aish_sysimage.so -e 'using AISH; AISH.main()' "$@"
