import matplotlib.pyplot as plt
import numpy as np
import math
import stumpy
from matplotlib.patches import Rectangle
from matplotlib import rc
from sklearn import preprocessing

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


#plt.style.use("seaborn-white")
rc('font',**{'family':'serif','serif':['Georgia']})
plt.rcParams.update({'font.size': 10})
rc('text', usetex=True)


fig, ax = plt.subplots()

fig.set_size_inches(8, 3)

# plot lineplot black with dots on values
ax.plot(T, 'ko-')

# add query sequence
rect = Rectangle((i, 0), m - 1, max(T), facecolor='lightgreen', label=r"$T_{i,m}$")
ax.add_patch(rect)

# add compared sequence
rect = Rectangle((j, 0), m - 1, max(T), facecolor='lightblue', label=r"$T_{j,m}$")
ax.add_patch(rect)

# add legend
# ax.legend(prop={'size': 11}, ncol=2, frameon=False, loc='lower center')

# removes axes
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
# set limits
ax.set_ylim([0, 17])

# set only vertical lines grid
ticks = np.arange(0, len(T), 1)
ax.set_xticks(ticks)
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

plt.savefig('./figures/MP-basic-distance-profiles.png', dpi = 300)


####
import numpy as np
import matplotlib.pyplot as plt

fig, ax = plt.subplots()

min_val, max_val = 0, 15

intersection_matrix = np.random.randint(0, 10, size=(max_val, max_val))

ax.matshow(intersection_matrix, cmap=plt.cm.Blues)

for i in range(15):
    for j in range(15):
        c = intersection_matrix[j,i]
        ax.text(i, j, str(c), va='center', ha='center')

plt.show()
