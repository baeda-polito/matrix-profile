import numpy as np
import math
import stumpy
# import custom plots
from utils_plot import plot_T_D, plot_T_Tij

# timeseries definition
T = np.asarray([0, 1, 3, 2, 9, 1, 14, 15, 1, 2, 2, 10, 7])
print('Timeseries T =', T)

# timeseries length
n = len(T)
print('Timeseries Length n =', n)

# window size
m = 4
print('Window size m =', m)

# query subsequence definition
i = 0
T_im = T[i:i + m]
print('Subsequence T_im =', T_im)
print('Starting at position i = ', i, '(first in position 0)')

# compare subsequence definition
j = 9
T_jm = T[j:j + m]
print('Subsequence T_jm =', T_jm)
print('Starting at position j = ', j, '(first in position 0)')

# distance among subsequences
# under not normalized euclidean distance
d_ij = 0
d_ij2 = 0
for k in range(m):
    d_ij2 += (T[i + k] - T[j + k]) ** 2
d_ij = math.sqrt(d_ij2)

print('Not normalized Euclidean distance d_ij,e =', d_ij)

# distance profile
D_i_e = np.empty([n - m + 1])  # under not normalized euclidean distance
D_i_ze = np.empty([n - m + 1])  # under z normalized euclidean distance
i = 0
j = 0

for tt in range(n - m + 1):
    # not notmalized
    d_ij_e = 0
    d_ij2_e = 0

    for k in range(m):
        d_ij2_e += (T[i + k] - T[j + k]) ** 2

    d_ij_e = math.sqrt(d_ij2_e)

    D_i_e[[tt]] = d_ij_e

    j = j + 1

print('Not normalized Euclidean distance profile D_i,e =', D_i_e)

# do the same with the build in function mass

T_im = T_im.astype('float64')
T = T.astype('float64')

D_i_e = stumpy.core.mass_absolute(Q=T_im, T=T)
D_i_ze = stumpy.core.mass(Q=T_im, T=T)

# visualize timeseries in a simple plot

# reset parameters
i = 0
j = 9

# plots and saves figure in fig directory
plot_T_D(T=T, i=i, j=j, m=m, D_i_e=D_i_e, D_i_ze=D_i_ze)


# plot gif
for j in range(n - m + 1):
    plot_T_Tij(T=T, i=i, j=j, m=m, D_i=D_i_e, label=r"Not Normalized Distance Profile")
