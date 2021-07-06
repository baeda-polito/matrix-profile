import matplotlib.pyplot as plt
import numpy as np
import stumpy
from matplotlib.patches import Rectangle
from matplotlib import rc


# define a function to visualize and plot timeseries
def plot_T_Tij(T, i, j, m, D_i, label):
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

    ax.text(12.5, 15, '$$T_{i,m} = T_{'+str(i)+','+str(m)+'}$$',
            color='green',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 13.5, '$$T_{j,m} = T_{'+str(j)+','+str(m)+'}$$',
            color='blue',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 12, 'i = ' + str(i),
            color='black',
            fontsize=annotation_fontsize,
            bbox=dict(facecolor='white', fill='white', edgecolor='white', boxstyle='round,pad=0'))

    ax.text(12.5, 10.5, 'j = ' + str(j),
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


    #plt.show()
    plt.savefig('./figures/MP-basic-gif-' + str(j) + '.png', dpi=200)


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

# do the same with the build in function mass
T_im = T_im.astype('float64')
T = T.astype('float64')

D_i_e = stumpy.core.mass_absolute(Q=T_im, T=T)
# D_i_ze = stumpy.core.mass(Q=T_im, T=T)

for j in range(n - m + 1):
    plot_T_Tij(T=T, i=i, j=j, m=m, D_i=D_i_e, label=r"Not Normalized Distance Profile")
