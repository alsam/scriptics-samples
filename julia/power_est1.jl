#!/bin/env julia

#Base.compilecache(GP)

#include("./GP.jl")
import GP
#using GP

if length(ARGS) < 2
    println("give me input file names")
    exit(0)
end

input = ARGS

@time GP.process(input[1])
@time GP.process(input[2])
