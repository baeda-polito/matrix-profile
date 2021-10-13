import stumpy
import numpy as np
from scipy import signal
import matplotlib.pyplot as plt
from matplotlib import rc
import pandas as pd


# create syntetic data
noise = np.random.normal(0, 0.05, 1000)
up = np.abs(np.sin(20*np.pi/1000*np.arange(0, 1000, 1)))
down = -np.abs(np.sin(20*np.pi/1000*np.arange(0, 1000, 1)))
sig = np.zeros(1000)
sig[0:250] += up[0:250]
sig[250:500] += down[250:500]
sig[500:1000] += sig[0:500]
sig += noise

# plt.style.use("seaborn-white")
rc('font', **{'family': 'serif', 'serif': ['Georgia']})
plt.rcParams.update({'font.size': 10})
rc('text', usetex=True)

fig, (ax_T, ax_znorm, ax_notnorm, ax_kMP) = plt.subplots(4, 1, sharey='row')

fig.set_size_inches(5, 5)

# plot lineplot black with dots on values
# timeseries
T =sig
m = 50

ax_T.plot(T, 'k-')

# plot lineplot black with dots on values

# normalized matrix profile
matrix_profile_znorm = stumpy.stump(T, m=m, normalize=True)
ax_znorm.plot(matrix_profile_znorm[:,0], 'k-')

# not normalized matrix profile
matrix_profile_notnorm = stumpy.stump(T, m=m, normalize=False)
ax_notnorm.plot(matrix_profile_notnorm[:,0], 'k-')


## empty Matrix for the end results
matrix_complete = []
ez = int(np.ceil(m / 4))
n = len(T)
# distance profile
D_i_e = np.empty([n - m + 1])  # under not normalized euclidean distance
# distance profile length
n_dp = len(D_i_e)
i=0
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
k=1
colorss = ['k-', 'r-', 'g-', 'c-']
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

    pd.DataFrame(matrix_profile).to_csv("./data/prova_kMP_"+str(k)+".csv")

    ax_kMP.plot(matrix_profile[:, 1], colorss[k], linewidth=0.1)

plt.savefig('./figures/MP-bagging-comparison.png', dpi=300)
plt.show()


pd.DataFrame(T).to_csv("./data/prova_T.csv")
pd.DataFrame(matrix_profile_znorm).to_csv("./data/prova_matrix_profile_znorm.csv")
pd.DataFrame(matrix_profile_notnorm).to_csv("./data/prova_matrix_profile_notnorm.csv")