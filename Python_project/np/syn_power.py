import stumpy
import numpy as np
import pandas as pd
import stumpy
from scipy import signal
import matplotlib.pyplot as plt
from matplotlib import rc
from sklearn.preprocessing import scale

from nprofile import NeighborProfile
import utils

# plt.style.use("seaborn-white")
rc('font', **{'family': 'serif', 'serif': ['Georgia']})
plt.rcParams.update({'font.size': 15})
rc('text', usetex=True)

d = 96

# load the POLITO dataframe small from csv
df_power = pd.read_csv("./data/df_univariate_small.csv")
df_power.head()

sig = df_power['Power_total']

list_of_np = [[], [], [], []]
for idx, max_sample in enumerate([2, 16, 32, 50]):
    nprofile = NeighborProfile(max_sample=max_sample).fit(sig, d=d)
    list_of_np[idx] = nprofile.estimate_for_time_series(sig)

np1, np2, np3, np4 = list_of_np
mp = stumpy.stump(sig, m=d)
mp = mp[:, 0]

## visualization

f, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(8, 6), gridspec_kw={'height_ratios': [1, 1, 2.5]})  # sharex=True,
plt.subplots_adjust(hspace=0.6)  # , left=0.05, right=0.95)

ax1.plot(sig, color="k")
ax2.plot(mp, color="r")
ax3.plot(np1, color="b", label=r"$s=8$")
ax3.plot(np2, label=r"$s=16$")
ax3.plot(np3, label=r"$s=32$")
ax3.plot(np4, label=r"$s=64$")

ax1.text(split / 2, 1.1, r"pos-sin", fontsize=11)
ax1.text(split, 0.5, r"pos-neg", fontsize=11)
ax1.text(500 + split / 2, 0.1, r"neg-sin", fontsize=11)
ax3.legend(prop={'size': 11}, ncol=2, frameon=False)

ax1.spines['top'].set_visible(False)
ax1.spines['right'].set_visible(False)
ax1.spines['bottom'].set_visible(False)

ax2.spines['top'].set_visible(False)
ax2.spines['right'].set_visible(False)
ax2.spines['bottom'].set_visible(False)

ax3.spines['top'].set_visible(False)
ax3.spines['right'].set_visible(False)
ax3.spines['bottom'].set_visible(False)

ax1.set_xlabel(r"(i) synthetic series")
ax2.set_xlabel(r'(ii) matrix profile ($m=50$)')
ax3.set_xlabel(r'(iii) neighbor profiles ($m=50$)')

f.show()

# f.savefig("syn/{}.png".format(split), dpi=300, bbox_inches="tight")
