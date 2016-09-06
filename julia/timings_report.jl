#!/bin/env julia

# The MIT License (MIT)
# 
# Copyright (c) 2015 Alexander Samoilov
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

using DocOpt

macro p_str(s) s end
const rexp_dir = r"\s*([\w]+)/"
#const rexp_abc = r"^ABC:\s*([\w]+)\s+(\d+.\d+)\s+(\d+.\d+)\s+(\d+)"
const transcript_rexp_suf = p"\s*([\w]+)\s+(\d+.\d+)\s+(\d+.\d+)\s+(\d+)"
const rexp_abc_prefix = p"^ABC:"
const rexp_abcdef_prefix = p"^ABCDEF:"
const rexp_abc    = Regex("$rexp_abc_prefix$transcript_rexp_suf")
const rexp_abcdef = Regex("$rexp_abcdef_prefix$transcript_rexp_suf")

type TestSummary
    name::AbstractString
    exec_time::Float64
    grad_time::Float64
    ratio::Float64

    # a constructor
    TestSummary(n::AbstractString = "") = new(n, 0, 0, 0)
end

@enum State none test_name exec_time gradient_time

function main()

    const script_name = basename(@__FILE__)
    const doc = """$script_name

Postprocess transcript files - get timers statistics.

Usage:
  $script_name -h | --help
  $script_name [-v | --verbose] [-s | --def] <input> [<output>]

Options:
  -h --help                  Show this screen.
  -s --DEF                   DEF mode.
"""

    if length(ARGS) < 1
        #println("$rexp_abc")
        #println("$rexp_abcdef")
        println(doc)
        exit(0)
    end

    arguments = docopt(doc)

    verbose = arguments["--verbose"]
    def     = arguments["--def"]
    fname   = arguments["<input>"]

    rexp = def ? rexp_abcdef : rexp_abc
    state = none
    summary = TestSummary[]
    open(fname,"r") do f
        d = Dict{AbstractString, UInt}()
        test_summary = TestSummary()
        for line in eachline(f)
            # print(line) ##
            test_name_m = match(rexp_dir, line)
            if test_name_m != nothing
                if verbose println("Bingo test name: $(test_name_m[1])") end
                state = test_name
                test_summary = TestSummary(test_name_m[1])
            end
            abc_time_m = match(rexp, line)
            if abc_time_m != nothing
                if verbose
                    println("Bingo abc time counter: $(abc_time_m[1]) "
                          * "elapsed time: $(abc_time_m[2]) "
                          * "real_time: $(abc_time_m[3]) "
                          * "# of repetitions:  $(abc_time_m[4])")
                end
                if abc_time_m[1] == "EXEC"
                    state = exec_time
                    if test_summary.exec_time == 0.0
                        test_summary.exec_time = parse(Float64,abc_time_m[3])
                    end
                end
                if abc_time_m[1] == "GRADIENT"
                    state = gradient_time
                    test_summary.grad_time = parse(Float64,abc_time_m[3])
                    # get all we needed - computue ratio, push to summary and switch to `none`
                    test_summary.ratio = test_summary.grad_time / test_summary.exec_time
                    tname = test_summary.name
                    if !haskey(d,tname)
                        push!(summary,test_summary)
                        #println("$(test_summary)")
                        d[tname] = 1
                    else
                        d[tname] = d[tname] + 1
                    end
                    state = none
                end
            end
        end
    
        sort!(summary, lt = (a,b) -> a.ratio > b.ratio)
        for s in summary
            println("$s")
        end
    
        # now emit csv
        f = open("$(fname).csv", "w")
        @printf(f, "%-48.48s, %7.7s, %7.7s, %5.5s%%\n", "Test name", "Exec. s", "Grad. s", "ratio")
        for s in summary
            (name, etime, gtime, ratio) = (s.name, s.exec_time, s.grad_time, s.ratio)
            if ratio < 1.0 # cut erroneous
                @printf(f, "%-48.48s, %7.1f, %7.1f, %5.2f%%\n", name, etime, gtime, ratio * 100)
            end
        end
    end
end

main()
