#!/usr/bin/env python3 
#-*- coding: utf-8 -*-

from os import listdir
from os.path import isfile, join
from pathlib import PurePath
import subprocess

def get_matrices(matrices_path):
    def is_block_matrix(s):
        return s.split('.')[-2] == 'm_bsr'

    def poly_deg(s):
        return s.split('_')[2]

    def block_size(s):
        if (s == '1'): return '3'
        if (s == '2'): return '6'
        if (s == '3'): return '10'
        else: return '1'

    def matrix_size(s):
        return s.split('.')[0].split('_')[-1]

    def block_option(s):
        if is_block_matrix(s):
            block_siz = block_size(poly_deg(s))
            return ' -b ' + block_siz +  ' -p aggr.block_size=' + block_siz + ' '
        else:
            return ' '

    matrices_files = [f for f in listdir(matrices_path)
                        if isfile(join(matrices_path, f))
                        and f.endswith('.mtx')
                        and int(matrix_size(f)) >= 20]
    only_regular_cases = ['-A ' + str(PurePath(matrices_path, f)) + block_option(f)
                          for f in matrices_files if 'regular' in f]
    #print(only_regular_cases)
    return only_regular_cases

def gen_params(param_name, param_set):
    return ['-p ' + param_name + '=' + p for p in param_set]

if __name__ == '__main__':
    matrices_path = '/media/DATA2/shared_amg'
    only_regular_cases = get_matrices(matrices_path)
    #print('only_regular_cases', only_regular_cases)
    #path_prefix = '/home/asamoilov/data/work/github/cpp-samples/amgcl.starter'
    path_prefix = '/home/asamoilov/data/work/amgcl.starter'
    build_paths = [ # 'build_debug1' ,
                    #'build_double_release1' ,
                    # 'build_double_vexcl' ,
                    'build_double_vexcl_release' ,
                    #'build_float_release1' ,
                    # 'build_float_vexcl_debug' ,
                    'build_float_vexcl_release' , ]
    exe_paths = [PurePath(path_prefix, p) for p in build_paths]
    #print(exe_paths)

    solvers = [ 'solver_cuda',
                'solver_vexcl_cuda',
                'solver', ]

    solvers_paths = [str(PurePath(exe_path, s)) for exe_path in exe_paths for s in solvers]
    #print(solvers_paths)

    ## enum type {
    ##     cg,         ///< Conjugate gradients method
    ##     bicgstab,   ///< BiConjugate Gradient Stabilized
    ##     bicgstabl,  ///< BiCGStab(ell)
    ##     gmres,      ///< GMRES
    ##     lgmres,     ///< LGMRES
    ##     fgmres,     ///< FGMRES
    ##     idrs,       ///< IDR(s)
    ##     richardson, ///< Richardson iteration
    ##     preonly     ///< Only apply preconditioner once
    ## };

    solver_type = [ 'cg', 'gmres', ]
    solver_type_params = gen_params('solver.type', solver_type)

    iters_before_restart = [ '150' ]
    iters_restart_params =  gen_params('solver.M', iters_before_restart)

    ## /// Relaxation schemes.
    ## enum type {
    ##     gauss_seidel,               ///< Gauss-Seidel smoothing
    ##     ilu0,                       ///< Incomplete LU with zero fill-in
    ##     iluk,                       ///< Level-based incomplete LU
    ##     ilup,                       ///< Level-based incomplete LU (fill-in is determined from A^p pattern)
    ##     ilut,                       ///< Incomplete LU with thresholding
    ##     damped_jacobi,              ///< Damped Jacobi
    ##     spai0,                      ///< Sparse approximate inverse of 0th order
    ##     spai1,                      ///< Sparse approximate inverse of 1st order
    ##     chebyshev                   ///< Chebyshev relaxation
    ## };

    relax_schemes = [ 'gauss_seidel', 'ilu0', 'damped_jacobi', 'spai0', 'chebyshev', ]
    relax_params = gen_params('precond.relax.type', relax_schemes)

    ## enum type {
    ##     ruge_stuben,            ///< Ruge-Stueben coarsening
    ##     aggregation,            ///< Aggregation
    ##     smoothed_aggregation,   ///< Smoothed aggregation
    ##     smoothed_aggr_emin      ///< Smoothed aggregation with energy minimization
    ## };

    coarsening_kind = [
         'ruge_stuben',
         'aggregation',
         'smoothed_aggregation',
         'smoothed_aggr_emin', ]
    coarsening_params = gen_params('precond.coarsening.type', coarsening_kind)

    params = ['-p solver.maxiter=500 ' +
              s+' '+i+' '+r+' '+c for s in solver_type_params
                                  for i in iters_restart_params
                                  for r in relax_params
                                  for c in coarsening_params]
    #print(params)

    run_cmdlines = [(exe, mat, prm) for exe in solvers_paths for mat in only_regular_cases for prm in params]
    #print(run_cmdlines)
    for cmd in run_cmdlines:
        delim = ' '
        real_cmd = delim.join(cmd)
        cmd2 = real_cmd.split()
        process = subprocess.Popen(cmd2, stdout=subprocess.PIPE)
        for line in process.stdout:
            print(line.rstrip().decode("utf-8"))

