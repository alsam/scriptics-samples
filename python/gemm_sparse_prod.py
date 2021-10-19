#!/usr/bin/env python3

import scipy.sparse, scipy.io

m = 150
n = 200
k = 250

A=scipy.sparse.random(m, n, density=0.01, format='csr')
B=scipy.sparse.random(n, k, density=0.01, format='csr')
C=A.dot(B)

def out_mat(label, mat):
    print('int nnz' + label + ' = ', mat.nnz, ';')
    print('thrust::host_vector<double> h_csrVal' + label + '(nnz' + label + ');')
    print('thrust::host_vector<int> h_csrColInd' + label + '(nnz' + label + ');')
    print('thrust::host_vector<int> h_csrRowPtr' + label + '(', len(mat.indptr), ');')
    print('{')
    print('    double tmp_h_csrVal' + label + '[] = {', ','.join(map(str, mat.data)), '};')
    print('    int tmp_h_csrColInd' + label + '[] = {', ','.join(map(str, mat.indices)), '};')
    print('    int tmp_h_csrRowPtr' + label + '[] = {', ','.join(map(str, mat.indptr)), '};')
    print('    h_csrVal' + label + '.assign(tmp_h_csrVal' + label + ', tmp_h_csrVal' + label + '+nnz' + label + ');')
    print('    h_csrColInd' + label + '.assign(tmp_h_csrColInd' + label + ', tmp_h_csrColInd' + label + '+nnz' + label + ');')
    print('    h_csrRowPtr' + label + '.assign(tmp_h_csrRowPtr' + label + ', tmp_h_csrRowPtr' + label + '+', len(mat.indptr), ');')
    print('}')

out_mat('A', A)
out_mat('B', B)
out_mat('C', C)

scipy.io.mmwrite(target='A.mtx', a=A)
scipy.io.mmwrite(target='B.mtx', a=B)
scipy.io.mmwrite(target='C.mtx', a=C)
