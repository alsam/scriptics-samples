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
using DataFrames

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

function parse_case(case_params::Vector{Tuple{String, String}}, precision_data::AbstractString, case_data::AbstractString)
    #println("case_data: ", case_data)
    #println("precision_data: ", precision_data)
    precision = match(r"(float|double)", precision_data)
    d = split(case_data)
    matrix_name = basename(d[1])
    matrix_name_elems = split(first(split(matrix_name, ".")),"_")
    matrix_size = last(matrix_name_elems)
    polynomial_degree = matrix_name_elems[3]
    push!(case_params, ("precision", precision[1]))
    push!(case_params, ("matrix_name", matrix_name))
    push!(case_params, ("matrix_size", matrix_size))
    push!(case_params, ("polynomial_degree", polynomial_degree))
    params = [Tuple(String(x) for x in split(z, "=")) for z in d if occursin("=", z)]
    for z in params
        push!(case_params, z)
    end
end

function main()
    if length(ARGS) < 1
        println("gimme input")
        exit(0)
    end

    ifname = ARGS[1]
    state = none
    summary = TimingsSummary[]
    dfs = DataFrame()
    open(ifname, "r") do f
        timing_summary = TimingsSummary()
        case_params = Vector{Tuple{String, String}}()
        for line in eachline(f)
            ##println(line)
            m = match(r"(.+)(solver.*)\s+\-A\s+(.+)", line)
            if m != nothing
                parse_case(case_params, m[1], m[3])
                insert!(case_params, 3, ("solver_program", m[2]))
                #@printf("solver: %s matrix: %s\n", m[2], m[3])
                #println("case_params: ", case_params)
                timing_summary = TimingsSummary(m[2], m[3])
                state = test_name
                continue
            end
            m = match(r"rows:\s*(\d+)", line)
            if m != nothing
                timing_summary.rows = parse(Int, m[1])
                push!(case_params, ("rows", m[1]))
                #@printf("error: %d\n", timing_summary.rows)
                state = rows
                continue
            end
            m = match(r"Iterations:\s*(\d+)", line)
            if m != nothing
                timing_summary.iterations = parse(Int, m[1])
                push!(case_params, ("iterations", m[1]))
                #@printf("error: %d\n", timing_summary.iterations)
                state = iterations
                continue
            end
            m = match(Regex("Error:\\s*($flt_regexp)"), line)
            if m != nothing
                timing_summary.error = parse(Float64, m[1])
                push!(case_params, ("error", m[1]))
                #@printf("error: %g\n", timing_summary.error)
                state = error
                continue
            end
            m = match(Regex("\\[\\s*setup:\\s*($flt_regexp)\\s*s\\](.+)"), line)
            if m != nothing
                timing_summary.setup_time = parse(Float64, m[1])
                push!(case_params, ("c.setup_time", m[1]))
                #insert!(case_params, 4, ("setup_time", m[1]))
                #@printf("setup_time: %g\n", timing_summary.setup_time)
                state = setup_time
                continue
            end
            m = match(Regex("\\[\\s*solve:\\s*($flt_regexp)\\s*s\\](.+)"), line)
            if m != nothing
                timing_summary.solve_time = parse(Float64, m[1])
                push!(case_params, ("c.solve_time", m[1]))
                #insert!(case_params, 3, ("solve_time", m[1]))
                #@printf("solve_time: %g\n", timing_summary.solve_time)
                state = solve_time
                continue
            end

            if state == solve_time # finished parsing the case
                #println("entry: $timing_summary")
                push!(summary, timing_summary)
                #println("case_params: ", case_params)
                df = DataFrame(Dict(case_params))
                #println(df)
                if ncol(df) >= 15
                    dfs = vcat(dfs, df)
                end
                case_params = Vector{Tuple{String, String}}()
                state = none
            end
        end
    end

    #println(describe(dfs))
    #println(dfs)

    speedup_dict = Dict{AbstractString, Vector{DataFrameRow}}()

    dfs_good = filter(row -> parse(Float64, row.error) < 1e-3 && parse(Int, row.iterations) < 100, dfs)
    println(dfs_good)

    for r in eachrow(dfs_good)
        #println(r)
        local m_name = r.matrix_name
        #println(matrix_name)
        if !haskey(speedup_dict, m_name)
            speedup_dict[m_name] = [r]
        else
            push!(speedup_dict[r.matrix_name], r)
        end
    end

    for (k, v) in speedup_dict
        println(k, " -> ", length(v))
        sort!(v, lt = (x,y) -> x."c.solve_time" < y."c.solve_time")
        println(NamedTuple(v[1]))
        println(NamedTuple(v[2]))
        println(NamedTuple(v[3]))
        println("===================================================================================================================================================================================\n\n")
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
            if sum.solver_type == "solver_cuda"
                gpu_result_idx = index
            else
                cpu_result_idx = index
            end
        end
        if gpu_result_idx > 0 && cpu_result_idx > 0
            local (cpu_info, gpu_info) = (summary[cpu_result_idx], summary[gpu_result_idx])
            #@printf("%s: CPU solve_time: %g GPU solve_time: %g speedup: %g CPU error: %g GPU error: %g\n",
            #        k, cpu_info.solve_time, gpu_info.solve_time,
            #        cpu_info.solve_time / gpu_info.solve_time, cpu_info.error, gpu_info.error)
        end
    end

end

@time main()
#@time main()

