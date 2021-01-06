__precompile__()

module GP
export process

using CSV
using Statistics
using DataFrames
using Printf

function process(input::String)
    try
        df = CSV.read(input, DataFrame)
        p = df."Power(mAh)"
        println("power: $p")
        m = Statistics.mean(p)
        d = Statistics.stdm(p, m)
        @printf("power: %.2f ± %.2f\n", m, d)
    catch e
    end
end

precompile(process, (String,))

end
