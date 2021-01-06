#!/bin/env julia

# __precompile__()

using CSV
using Statistics
using DataFrames
using Printf

if length(ARGS) < 1
    println("give me input file name")
    exit(0)
end

input = ARGS[1]

function process(input)
    df = CSV.read(input, DataFrame)
    p = df."Power(mAh)"
    println("power: $p")
    m = Statistics.mean(p)
    d = Statistics.stdm(p, m)
    @printf("power: %.2f ± %.2f\n", m, d)
end

@time process(input)
@time process(input)
