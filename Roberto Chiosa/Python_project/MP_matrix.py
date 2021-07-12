import matplotlib.pyplot as plt
import stumpy
import numpy as np
import pandas as pd
# import custom plots
from utils_plot import plot_MP, plot_full_dist_matrix
import statistics

# timeseries definition
# read from dataframe
T = pd.read_csv("./data/simple_timeseries_short.csv")
# T = pd.read_csv("./data/df_univariate_small.csv")
# convert as array
T = np.asarray(T["0"])
# T = np.asarray(T["Power_total"])
print('Timeseries T =', T)

# timeseries length
n = len(T)
print('Timeseries Length n =', n)

# window size
m = 4
# m = 94
print('Window size m =', m)

# exclusion zone
ez = 0
# ez = int(np.ceil(m / 4))
print('Exclusion zone ez =', ez)

# distance profile
D_i_e = np.empty([n - m + 1])  # under not normalized euclidean distance
D_i_ze = np.empty([n - m + 1])  # under z normalized euclidean distance

# distance profile length
n_dp = len(D_i_e)
print('Distance Profile Length n_dp =', n_dp)

# type conversion for mass function
T = T.astype('float64')

## empty Matrix for the end results
matrix_complete = []

for i in range(n - m + 1):
    # type conversion for mass function
    T_im = T[i:i + m].astype('float64')
    D_i_e = stumpy.core.mass_absolute(Q=T_im, T=T)

    zone_start = i - ez
    zone_end = i + ez + 1  # Notice that we add one since this is exclusive

    if zone_start < 0:
        zone_start = 0
    if zone_end > n_dp:
        zone_end = n_dp

    remove = [u for u in range(zone_start, zone_end)]

    D_i_e[remove] = np.nan

    matrix_complete.append(D_i_e)

# convert to type matrix
matrix_complete = np.asmatrix(matrix_complete)

# get minimum
# add last columns
morecolumns = n - n_dp
X0 = np.empty((n_dp, morecolumns))
X0[:] = np.nan
matrix_complete = np.hstack((matrix_complete, X0))

print('full distance matrix =', matrix_complete)

# plot ful distance matrix
plot_full_dist_matrix(matrix_full=matrix_complete, annotate=True)

# construct matrix profile and plot
matrix_complete1 = matrix_complete
k=0
# define the number of neighbor and find the corresponding matrix profile
for k in range(0, 4):

    # order in descending way the values for each row
    matrix_complete1_idx_ordered = np.argpartition(matrix_complete1, k)

    # get the index of those corresponding to the nn selected
    index_nn = np.asarray(matrix_complete1_idx_ordered[:, k])

    # construct matrix profile
    matrix_profile = []
    for i in range(0, n_dp):
        mp_index = index_nn[i]
        mp_value = np.asarray(matrix_complete1[i, index_nn[i]])
        mp_row = np.c_[mp_index, mp_value]

        matrix_profile.append(mp_row)

    # transpose matrix
    matrix_profile = np.asmatrix(np.array(matrix_profile))

    # check that the stump algoritms does the same
    # matrix_profile = stumpy.stump(T, m=m, normalize=False)

    # convert to plot
    # matrix_profile_plot = np.asmatrix(matrix_profile.astype('float64'))
    # matrix_profile_plot = matrix_profile_plot[:, 0]

    plot_MP(matrix_profile_plot=matrix_profile, kNN=str(k + 1), annotate=True)
