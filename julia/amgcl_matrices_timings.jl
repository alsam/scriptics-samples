#!/bin/env julia

# The MIT License (MIT)
# 
# Copyright (c) 2021 Alexander Samoilov
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#using DocOpt
using Printf

mutable struct TimingsSummary
    matrix_name::AbstractString
    rows::Int
    cols::Int
    solver_type::AbstractString
    processor::AbstractString
    setup_time::Float64
    solve_time::Float64
    iterations::Int
    error::Float64

    # a constructor
    TimingsSummary(s::AbstractString = "", m::AbstractString = "") =
        new(m, 0, 0, s, "CPU", 0, 0, 0, 0)
end

const flt_regexp = "\\-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?"
const sp_rexp = "\\s*"

function main()
    if length(ARGS) < 1
        println("gimme input")
        exit(0)
    end

    ifname = ARGS[1]
    open(ifname, "r") do f
        timing_summary =TimingsSummary()
        for line in eachline(f)
            ##println(line)
            m = match(r"(\./)?solver(.*)\s+\-A\s+(.+)", line)
            if m != nothing
                #@printf("solver: %s matrix: %s\n", m[2], m[3])
                timing_summary = TimingsSummary(m[2], m[3])
            end
            m = match(Regex("Error:$sp_rexp($flt_regexp)"), line)
            if m != nothing
                timing_summary.error = parse(Float64, m[1])
                @printf("error: %g\n", timing_summary.error)
            end
            #m = match(r"\[\s*setup:\s*(-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)", line)
            ##m = match(Regex("\\[($sp_rexp)setup:$sp_rexp($flt_regexp)"), line)
            println("entry: $timing_summary")
        end
    end
end

main()



