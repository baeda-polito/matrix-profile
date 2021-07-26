import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import stumpy
from matplotlib.patches import Rectangle

# load the POLITO dataframe small from csv
df_power = pd.read_csv("./data/df_two_months.csv")
df_power.head()

# time window length
w = 96

# perform MP calculation with euclidean distance
mp = stumpy.stump(df_power['Power_total'], w, normalize=False)

# transform the MP into a dataframe and export to csv
pd.DataFrame(mp).to_csv("./data/mp_euclidean_tm.csv")

# find discord
yy_mp = mp[:, 0]
n_discord = np.arange(len(yy_mp) - 1, len(yy_mp) - 3, -1)
discord_idx = np.argsort(mp[:, 0])[n_discord]
print(f"The discord is located at index {discord_idx}")

# plot
fig, axs = plt.subplots(2, sharex=True, gridspec_kw={'hspace': 0})
plt.suptitle('Discord Analysis', fontsize='20')
axs[0].set_ylabel("Power[kW]", fontsize='12')
axs[0].plot(df_power['Power_total'], alpha=0.5, linewidth=1)

rows = np.arange(0, len(yy_mp), 1)
axs[1].set_ylabel("Euclidean_MP", fontsize='12')
axs[1].plot(rows, yy_mp, linewidth=1)

# plot discord
rect = Rectangle((discord_idx[0], 0), w, 800, facecolor='lightgrey')
axs[0].add_patch(rect)
# rect = Rectangle((533, 0), w, 800, facecolor='lightgrey')
axs[0].add_patch(rect)
axs[1].axvline(x=discord_idx[0], linestyle="dashed",color='red')
# axs[1].axvline(x=533, linestyle="dashed",color='red')
axs[0].grid()
axs[1].grid()
plt.show()
fig.savefig('MP_euclidean.png')



