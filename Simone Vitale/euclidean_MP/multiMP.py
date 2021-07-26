import pandas as pd
import stumpy
import numpy as np
import numpy.testing as npt
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
plt.rcParams["figure.figsize"] = [20, 10]  # width, height
plt.rcParams['xtick.direction'] = 'out'

# import data frame
df = pd.read_csv("./data/df_two_months.csv")
df.drop(df.iloc[:, 0:11], inplace = True, axis=1)
#df.drop(df.iloc[:,[2]], inplace = True, axis=1)
#to_del=np.arange(80000,156578,1)
#df.drop(df.index[to_del],inplace=True)
Power_total=df['Power_total']
df.drop(df.iloc[:,[0]], inplace = True, axis=1)
#df = df.rename(columns = {'Power_total': 'P_t', 'Power_mechanical_room': 'P_m_r', 'Power_dimat': 'P_d'}, inplace = False)
#df.head()

#MP_Power_total
w=96
mp = stumpy.stump(Power_total, w, normalize=False)

#find discord
n_discord = np.arange(len(mp[:,0]) - 1, len(mp[:,0]) - 3, -1)
discord_index = np.argsort(mp[:, 0])[n_discord]


fig, ax = plt.subplots()
rows = np.arange(0, len(mp), 1)
ax.plot(rows,mp[:,0])
ax.plot(range(discord_index[0], discord_index[0] + w), mp[range(discord_index[0], discord_index[0] + w),0], c='red', linewidth=2)
ax.set_ylabel("Non-normalized_MP", fontsize='14')
fig.set_size_inches(20, 5)
plt.show()

#Compute the multi-dimensional MP

mps, indices = stumpy.mstump(df, w, discords=True, normalize= False)
# find discords
discords_idx=np.argsort(mps, axis=1)[:,-4:-1]

#figure
fig, axs = plt.subplots(mps.shape[0] * 2, sharex=True, gridspec_kw={'hspace': 0})
for k, dim_name in enumerate(df.columns):
     axs[k].set_ylabel(dim_name, fontsize='12',rotation=0,ha='right')
     #axs[k].tick_params(axis='both', which='major', labelsize=10)
     axs[k].plot(df[dim_name])
     axs[k].set_xlabel('Time', fontsize ='12')

     axs[k + mps.shape[0]].set_ylabel((str(k+1)+' MMP'), fontsize='12',rotation=0,ha='right')
     axs[k + mps.shape[0]].plot(mps[k], c='orange')
     axs[k + mps.shape[0]].set_xlabel('Time', fontsize ='12')

     axs[k].axvline(x=discords_idx[0, 0], linestyle="dashed", c='black')
     axs[k].axvline(x=discords_idx[0, 1], linestyle="dashed", c='black')
     axs[k].axvline(x=discords_idx[0, 2], linestyle="dashed", c='black')

     axs[k + mps.shape[0]].axvline(x=discords_idx[0, 0], linestyle="dashed", c='black')
     axs[k + mps.shape[0]].axvline(x=discords_idx[0, 1], linestyle="dashed", c='black')
     axs[k + mps.shape[0]].axvline(x=discords_idx[0, 2], linestyle="dashed", c='black')


     axs[k].plot(range(discords_idx[k, 0], discords_idx[k, 0] + w), df[dim_name].iloc[discords_idx[k, 0] : discords_idx[k, 0] + w], c='red', linewidth=1)
     axs[k].plot(range(discords_idx[k, 1], discords_idx[k, 1] + w), df[dim_name].iloc[discords_idx[k, 1] : discords_idx[k, 1] + w], c='lime', linewidth=1)
     axs[k].plot(range(discords_idx[k, 2], discords_idx[k, 2] + w), df[dim_name].iloc[discords_idx[k, 2] : discords_idx[k, 2] + w], c='g', linewidth=1)

     axs[k + mps.shape[0]].plot(discords_idx[k, 0], mps[k, discords_idx[k, 0]] + 1,marker="v", markersize=4, color='red')
     axs[k + mps.shape[0]].plot(discords_idx[k, 1], mps[k, discords_idx[k, 1]] + 1,marker="v", markersize=4, color='lime')
     axs[k + mps.shape[0]].plot(discords_idx[k, 2], mps[k, discords_idx[k, 2]] + 1, marker="v", markersize=4,color='g')

plt.show()

plt.plot(mps[range(mps.shape[0]), discords_idx[:, 2]], c='red', linewidth='4')
plt.xlabel('k (zero-based)', fontsize='20')
plt.ylabel('Matrix Profile Value', fontsize='20')
plt.xticks(range(mps.shape[0]))
#plt.plot(1, 1.3, marker="v", markersize=10, color='red')
plt.show()