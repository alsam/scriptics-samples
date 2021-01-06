#!/bin/env julia

#Base.compilecache(GP)

#include("./GP.jl")
import GP
#using GP

if length(ARGS) < 1
    println("give me input file name")
    exit(0)
end

input = ARGS[1]

@time GP.process(input)
@time GP.process(input)
