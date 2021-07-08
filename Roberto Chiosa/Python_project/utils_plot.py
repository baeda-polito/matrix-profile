import numpy as np
import matplotlib.pyplot as plt
from matplotlib import rc
from matplotlib.patches import Rectangle
from matplotlib.colors import ListedColormap


# define a function to visualize and plot timeseries
def plot_T_D(T, i, j, m, D_i_e, D_i_ze):
    """Plot the timeseries with distance vector.

                :param T: timeseries
                :type T: array

                :param i: the query starting index T_{i,m}
                :type i: int

                :param j: the subsequence starting index T_{j,m}
                :type j: int

                :param m: the time window length
                :type m: int

                :param D_i_e: the distance profile euclidean
                :type D_i_e: array

                :param D_i_ze: the distance profile euclidean
                :type D_i_ze: array

                :returns: An image is saved in the figures directory

    """

    # plt.style.use("seaborn-white")
    rc('font', **{'family': 'serif', 'serif': ['Georgia']})
    plt.rcParams.update({'font.size': 10})
    rc('text', usetex=True)

    fig, ax = plt.subplots()

    fig.set_size_inches(8, 3)

    # plot lineplot black with dots on values
    ax.plot(T, 'ko-')

    # add query sequence
    rect = Rectangle((i, 0), m - 1, max(T), facecolor='lightgreen', edgecolor='green', alpha=0.5, label=r"$T_{i,m}$")
    ax.add_patch(rect)

    # add compared sequence
    rect = Rectangle((j, 0), m - 1, max(T), facecolor='lightblue', edgecolor='blue', alpha=0.5, label=r"$T_{j,m}$")
    ax.add_patch(rect)

    # removes axes
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

    # set limits
    ax.set_ylim([0, 17])

    # set only vertical lines grid
    ticks = np.arange(0, len(T), 1)
    ax.set_xticks(ticks)

    # set thicks in order to beging with 1 instead of 0
    ticks_labels = np.arange(0, len(T), 1) + 1
    ax.set_xticklabels(ticks_labels)

    # add grid vertical
    ax.xaxis.grid(True, which='both', linestyle=':')

    # add annotations about not normalized euclidean disctance profile
    # trivial match
    annotation_fontsize = 10
    ax.text(0 - 0.1, 16, round(0, 1), color='black', fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))
    # others
    for gg in range(1, len(D_i_e)):
        ax.text(gg - 0.2, 16, round(D_i_e[gg], 1), color='black', fontsize=annotation_fontsize,
                bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))
    # label
    ax.text(9.5, 16, r"Not Normalized Distance Profile",
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    # add annotations about normalized euclidean disctance profile
    # trivial match
    ax.text(0 - 0.1, 17.8, round(0, 1), color='black', fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))
    # others
    for gg in range(1, len(D_i_e)):
        ax.text(gg - 0.2, 17.8, round(D_i_ze[gg], 1), color='black', fontsize=annotation_fontsize,
                bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))
    ax.text(9.5, 17.8, r"Z-Normalized Distance Profile",
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    # plt.show()

    plt.savefig('./figures/MP-basic-distance-profiles.png', dpi=300)


# define a function to visualize and plot matrix plofile
def plot_MP(matrix_profile_plot, kNN=1):
    """Plot matrix profile in matrix and lineplot form.

                :param matrix_profile_plot the matrix profile as matrix
                :type matrix_profile_plot: matrix

                :param kNN: the number of nearest neighbor to plot
                :type kNN: int

                :returns: An image is saved in the figures directory
    """
    # convert to mp matrix
    matrix_profile_plot = np.matrix(matrix_profile_plot)

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

    # set ticks in order to beging with 1 instead of 0
    yticks_labels = yticks + 1
    ax1.set_yticklabels(yticks_labels)

    # removes axes from all plots
    # ax1.axis('off')

    ax2.axis('off')

    # add numbers annotations on matrix profile
    for i in range(len(matrix_profile_plot)):
        #add mpindex
        c = round(matrix_profile_plot[i, 0])
        ax1.text(0, i, str(c), va='center', ha='center')
        # add mpvalue
        c = round(matrix_profile_plot[i, 1], 1)
        ax1.text(1, i, str(c), va='center', ha='center')

    # add matrix plofile lineplot
    ax2.plot(
        np.asarray(matrix_profile_plot[:,1]),
        np.array([i for i in range(len(matrix_profile_plot[:,1]))]),
        color='black'

    )
    plt.savefig('./figures/MP-basic-naive-matrix-profile-' + kNN + 'NN.png', dpi=300)


# define a function to plot fulla distance matrix
def plot_full_dist_matrix(matrix_full):
    """Plot matrix profile in matrix and lineplot form.

        :param matrix_full: full distance matrix
        :type matrix_full: matrix

        :returns: An image is saved in the figures directory

    """

    # plt.style.use("seaborn-white")
    rc('font', **{'family': 'serif', 'serif': ['Georgia']})
    plt.rcParams.update({'font.size': 10})
    rc('text', usetex=True)

    # define plot
    fig, ax = plt.subplots()

    # define plot size
    fig.set_size_inches(6, 6)

    # plot matrix
    ax.matshow(matrix_full, cmap=plt.cm.Blues)

    # length of timeseries (including NA)
    n = matrix_full.shape[1]

    # length of distance profile
    n_dp = matrix_full.shape[0]

    # adjust axes and ticks
    xticks = np.arange(0, n, 1)
    ax.set_xticks(xticks)

    # set ticks in order to beging with 1 instead of 0
    xticks_labels = xticks + 1
    ax.set_xticklabels(xticks_labels)

    # adjust axes and ticks
    yticks = np.arange(0, n_dp, 1)
    ax.set_yticks(yticks)

    # set ticks in order to beging with 1 instead of 0
    yticks_labels = yticks + 1
    ax.set_yticklabels(yticks_labels)

    # add numbers annotations
    for i in range(n):
        for j in range(n_dp):
            c = round(matrix_full[j, i], 1)
            ax.text(i, j, str(c), va='center', ha='center')

    # plt.show()
    plt.savefig('./figures/MP-basic-naive-matrix.png', dpi=300)


# define a function to visualize and plot timeseries
def plot_T_Tij(T, i, j, m, D_i, label):
    """Plot timeseries for the gif.

            :param T: timeseries
            :type T: array

            :param i: the query starting index T_{i,m}
            :type i: int

            :param j: the subsequence starting index T_{j,m}
            :type j: int

            :param m: the time window length
            :type m: int

            :param D_i: the distance profile to be plotted
            :type D_i: array

            :param label: string defining the distance profile on top
            :type label: str

            :returns: An image is saved in the figures directory

        """
    # plt.style.use("seaborn-white")
    rc('font', **{'family': 'serif', 'serif': ['Georgia']})
    plt.rcParams.update({'font.size': 10})
    rc('text', usetex=True)

    fig, ax = plt.subplots()

    fig.set_size_inches(8, 3)

    # plot lineplot black with dots on values
    ax.plot(T, 'ko-')

    # add query sequence
    rect = Rectangle((i, 0), m - 1, max(T), facecolor='lightgreen', edgecolor='green', alpha=0.5, label=r"$T_{i,m}$")
    ax.add_patch(rect)

    # add compared sequence
    rect = Rectangle((j, 0), m - 1, max(T), facecolor='lightblue', edgecolor='blue', alpha=0.5, label=r"$T_{j,m}$")
    ax.add_patch(rect)

    # removes axes
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    # set limits
    ax.set_ylim([0, 17])

    # set only vertical lines grid
    ticks = np.arange(0, len(T), 1)
    ax.set_xticks(ticks)

    # set thicks in order to beging with 1 instead of 0
    ticks_labels = np.arange(0, len(T), 1) + 1
    ax.set_xticklabels(ticks_labels)

    # add grid
    ax.xaxis.grid(True, which='both', linestyle=':')

    # add annotations about normalized euclidean disctance profile
    annotation_fontsize = 10

    # others
    for gg in range(i, j + 1):
        ax.text(gg - 0.2, 17.8, round(D_i[gg], 1), color='black', fontsize=annotation_fontsize,
                bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(9.5, 17.8, label,
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 15, '$$T_{i,m} = T_{' + str(i + 1) + ',' + str(m) + '}$$',
            color='green',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 13.5, '$$T_{j,m} = T_{' + str(j + 1) + ',' + str(m) + '}$$',
            color='blue',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 12, 'i = ' + str(i + 1),
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 10.5, 'j = ' + str(j + 1),
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 9, 'm = ' + str(m),
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 7.5, 'n = ' + str(len(T)),
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    # plt.show()
    plt.savefig('./figures/MP-basic-gif-' + str(j) + '.png', dpi=200)
