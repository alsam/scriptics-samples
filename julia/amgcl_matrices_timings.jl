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

macro p_str(s) s end
const flt_regexp = p"\-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?"

mutable struct TimingsSummary
    matrix_name::AbstractString
    rows::Int
    solver_type::AbstractString
    processor::AbstractString
    setup_time::Float64
    solve_time::Float64
    iterations::Int
    error::Float64

    # a constructor
    TimingsSummary(s::AbstractString = "", m::AbstractString = "") =
        new(m, 0, s, "CPU", 0, 0, 0, 0)
end

@enum State none test_name rows iterations error setup_time solve_time

function main()
    if length(ARGS) < 1
        println("gimme input")
        exit(0)
    end

    ifname = ARGS[1]
    state = none
    summary = TimingsSummary[]
    open(ifname, "r") do f
        timing_summary =TimingsSummary()
        for line in eachline(f)
            ##println(line)
            m = match(r"(\./)?solver(.*)\s+\-A\s+(.+)", line)
            if m != nothing
                #@printf("solver: %s matrix: %s\n", m[2], m[3])
                timing_summary = TimingsSummary(m[2], m[3])
                state = test_name
                continue
            end
            m = match(r"rows:\s*(\d+)", line)
            if m != nothing
                timing_summary.rows = parse(Int, m[1])
                #@printf("error: %d\n", timing_summary.rows)
                state = rows
                continue
            end
            m = match(r"Iterations:\s*(\d+)", line)
            if m != nothing
                timing_summary.iterations = parse(Int, m[1])
                #@printf("error: %d\n", timing_summary.iterations)
                state = iterations
                continue
            end
            m = match(Regex("Error:\\s*($flt_regexp)"), line)
            if m != nothing
                timing_summary.error = parse(Float64, m[1])
                #@printf("error: %g\n", timing_summary.error)
                state = error
                continue
            end
            m = match(Regex("\\[\\s*setup:\\s*($flt_regexp)\\s*s\\](.+)"), line)
            if m != nothing
                timing_summary.setup_time = parse(Float64, m[1])
                #@printf("setup_time: %g\n", timing_summary.setup_time)
                state = setup_time
                continue
            end
            m = match(Regex("\\[\\s*solve:\\s*($flt_regexp)\\s*s\\](.+)"), line)
            if m != nothing
                timing_summary.solve_time = parse(Float64, m[1])
                #@printf("solve_time: %g\n", timing_summary.solve_time)
                state = solve_time
                continue
            end

            if state == solve_time # finished parsing the case
                #println("entry: $timing_summary")
                push!(summary, timing_summary)
                state = none
            end
        end
    end

    sorted = sort!(summary, lt = (a,b) -> a.rows < b.rows)

    #println("sorted: $sorted")

    indices = Dict{AbstractString, Vector{UInt}}()
    for (index, entry) in enumerate(sorted)
        #println("$index: $entry")
        local test_name = entry.matrix_name
        if !haskey(indices, test_name)
            # a new one
            indices[test_name] = [index]
        else
            push!(indices[test_name], index)
        end
    end

    for (k, v) in indices
        #println("$k : $v")
        local (cpu_result_idx, gpu_result_idx) = (0, 0)
        for index in v
            sum = summary[index]
            if sum.solver_type == "_cuda"
                gpu_result_idx = index
            else
                cpu_result_idx = index
            end
        end
        if gpu_result_idx > 0 && cpu_result_idx > 0
            local (cpu_info, gpu_info) = (summary[cpu_result_idx], summary[gpu_result_idx])
            @printf("%s: CPU solve_time: %g GPU solve_time: %g speedup: %g\n",
                    k, cpu_info.solve_time, gpu_info.solve_time,
                    cpu_info.solve_time / gpu_info.solve_time)
        end
    end

end

@time main()
#@time main()

