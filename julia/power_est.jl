#!/bin/env julia

using CSV
using Statistics
using DataFrames
using Printf

if length(ARGS) < 1
    println("give me input file name")
    exit(0)
end

input = ARGS[1]

df = CSV.read(input, DataFrame)
p = df."Power(mAh)"
println("power: $p")
m = Statistics.mean(p)
d = Statistics.stdm(p, m)
@printf("power: %.2f +/- %.2f\n", m, d)
