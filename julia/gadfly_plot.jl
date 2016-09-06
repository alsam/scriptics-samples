#!/bin/env julia

using Gadfly, DataFrames

Gadfly.set_default_plot_size(28cm, 16cm)

fname = ARGS[1]

df = readtable(fname * ".csv")

p = plot(df, x=:Days_since_ref, y=:Obj, ymin=:Obj_min, ymax=:Obj_max, Geom.line, Geom.ribbon);

draw(PDF("$(fname).pdf", 5inch, 3inch), p)
draw(PNG("$(fname).png", 5inch, 3inch), p)

#fo = open("$(fname).df", "w")
#println(fo, "$df")

writetable("$(fname).dat", df, separator = '|')

