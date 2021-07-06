import stumpy
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import rc
from matplotlib import rc


# define a function to visualize and plot timeseries
def plot_MP(matrix_profile_plot, kNN = 1):

    matrix_profile_plot=np.matrix(matrix_profile_plot)

    # plt.style.use("seaborn-white")
    rc('font', **{'family': 'serif', 'serif': ['Georgia']})
    plt.rcParams.update({'font.size': 10})
    rc('text', usetex=True)

    # plot matrix profile
    fig, (ax1, ax2) = plt.subplots(1, 2, sharey='row')

    # define figure dimension
    fig.set_size_inches(3, 6)

    # create matrix visualization
    ax1.matshow(matrix_profile_plot, cmap=plt.cm.Blues)

    # adjust axes and thicks
    ax1.axes.xaxis.set_visible(False)
    yticks = np.arange(0, len(matrix_profile_plot), 1)
    ax1.set_yticks(yticks)

    # removes axes from all plots
    # ax1.axis('off')

    ax2.axis('off')

    # add numbers annotations on matrix profile
    for i in range(len(matrix_profile_plot)):
        c = round(matrix_profile_plot[i, 0], 1)
        ax1.text(0, i, str(c), va='center', ha='center')

    # add matrix plofile lineplot
    ax2.plot(
        np.asarray(matrix_profile_plot),
        np.array([i for i in range(len(matrix_profile_plot))]),
        color='black'

    )

    plt.savefig('./figures/MP-basic-naive-matrix-profile-'+kNN+'NN.png', dpi=300)


# timeseries definition
T = np.asarray([0, 1, 3, 2, 9, 1, 14, 15, 1, 2, 2, 10, 7])
print('Timeseries T =', T)

# timeseries length
n = len(T)
print('Timeseries Length n =', n)

# window size
m = 4
print('Window size m =', m)

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

    matrix_complete.append(D_i_e)

# convert to type matrix
matrix_complete = np.asmatrix(matrix_complete)

# get minimum
# add last columns
morecolumns = n - n_dp
X0 = np.empty((n_dp, morecolumns))
X0[:] = np.NaN
matrix_complete = np.hstack((matrix_complete, X0))

##### plot matrix

# plt.style.use("seaborn-white")
rc('font', **{'family': 'serif', 'serif': ['Georgia']})
plt.rcParams.update({'font.size': 10})
rc('text', usetex=True)

# define plot
fig, ax = plt.subplots()

# define plot size
fig.set_size_inches(6, 6)

# plot matrix
ax.matshow(matrix_complete, cmap=plt.cm.Blues)

# adjust axes and thicks
xticks = np.arange(0, n, 1)
ax.set_xticks(xticks)

yticks = np.arange(0, n_dp, 1)
ax.set_yticks(yticks)

# add numbers annotations
for i in range(n):
    for j in range(n_dp):
        c = round(matrix_complete[j, i], 1)
        ax.text(i, j, str(c), va='center', ha='center')

# plt.show()
plt.savefig('./figures/MP-basic-naive-matrix.png', dpi=300)

###### construct matrix profile and plot
matrix_complete1 = matrix_complete

# set to NaN zeros, ideally all those in the exclusion zone
for i, j in zip(range(0, n_dp), range(0, n_dp)):
    matrix_complete1[i, j] = np.nan

# define the number of neighbor and find the corresponding matrix profile
for k in range(0,4):

    # order in descending way the values for each row
    matrix_complete1_idx_ordered = np.argpartition(matrix_complete1, k)
    # get the index of those corresponding to the nn selected
    index_nn = np.asarray( matrix_complete1_idx_ordered[:,k] )

    # construct matrix profile
    matrix_profile = []
    for i in range(0,n_dp):
        value = np.asarray(matrix_complete1[i, index_nn[i] ])
        matrix_profile.append(value)

    # transpose matrix
    matrix_profile = np.asmatrix(np.array(matrix_profile)).transpose()

    # check that the stump algoritms does the same
    # matrix_profile = stumpy.stump(T, m=m, normalize=False)

    # convert to plot
    # matrix_profile_plot = np.asmatrix(matrix_profile.astype('float64'))
    # matrix_profile_plot = matrix_profile_plot[:, 0]

    plot_MP(matrix_profile_plot=matrix_profile, kNN=str(k+1))


