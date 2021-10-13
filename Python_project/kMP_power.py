import stumpy
import numpy as np
import pandas as pd
# import custom plots
from utils_plot import plot_MP, plot_full_dist_matrix

# timeseries definition
# read from dataframe
T = pd.read_csv("./data/df_univariate_small.csv")
# convert as array
T = np.asarray(T["Power_total"])

# timeseries length
n = len(T)

# window size
m = 96

ez = int(np.ceil(m / 4))

# distance profile
D_i_e = np.empty([n - m + 1])  # under not normalized euclidean distance

# distance profile length
n_dp = len(D_i_e)

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

    if zone_start<0:
        zone_start = 0
    if zone_end>n_dp:
        zone_end = n_dp

    remove = [u  for u in range(zone_start, zone_end)]

    D_i_e[remove] = np.nan

    matrix_complete.append(D_i_e)

# convert to type matrix
matrix_complete = np.asmatrix(matrix_complete)


# define the number of neighbor and find the corresponding matrix profile
for k in range(0, 4):

    # order in descending way the values for each row
    matrix_complete1_idx_ordered = np.argpartition(matrix_complete, k)

    # get the index of those corresponding to the nn selected
    index_nn = np.asarray( matrix_complete1_idx_ordered[:, k])

    # construct matrix profile
    matrix_profile = []
    for i in range(0, n_dp):
        mp_index = index_nn[i]
        mp_value = np.asarray(matrix_complete[i, index_nn[i] ])
        mp_row = np.c_[mp_index, mp_value]

        matrix_profile.append(mp_row)

    # transpose matrix
    matrix_profile = np.asmatrix(np.array(matrix_profile))

    # transform the MP into a dataframe and export to csv
    pd.DataFrame(matrix_profile).to_csv("./data/mp_not_normalized"+str(k+1)+"NN.csv")

    # check that the stump algoritms does the same
    # matrix_profile = stumpy.stump(T, m=m, normalize=False)

    # convert to plot
    # matrix_profile_plot = np.asmatrix(matrix_profile.astype('float64'))
    # matrix_profile_plot = matrix_profile_plot[:, 0]

    # plot_MP(matrix_profile_plot=matrix_profile, kNN=str(k+1))


