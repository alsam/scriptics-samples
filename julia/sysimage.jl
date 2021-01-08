using PackageCompiler
create_sysimage(:CSV, sysimage_path="sys_mycsv.so", precompile_execution_file="precompile_csv.jl")

