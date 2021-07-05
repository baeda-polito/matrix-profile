import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import stumpy

# load the POLITO dataframe small from csv
df_power = pd.read_csv("./data/df_two_months.csv")

w=96
exclusion_zone = 1 / 2
kk = 2

#compute distance profile
T_df=df_power['Power_total']

cumulative_profile = [0 for ii in range(len(df_power)-w+1)]

Q_df_1 = df_power['Power_total'][0:95]

for jj in range((len(df_power)-w+1)):

  distance_profile = stumpy.core.mass(Q_df_1, T_df)

  # find the idxs of the k-st NN

  distance_profile= np.where(distance_profile< exclusion_zone,float('nan'),distance_profile)
  idxs = np.argpartition(distance_profile, kk)[:kk]
  idxs = idxs[np.argsort(distance_profile[idxs])]

  # take the 2-NN
  idx=idxs[1]
  Q_df_2 = df_power['Power_total'][(0+idx):(95+idx)]
  cumulative_profile[jj]=sum(Q_df_1)-sum(Q_df_2)

  Q_df_1=Q_df_2

  #print(f"The second nearest neighbor to `Q_df` is located at idxs {idxs}  in `T_df`")

plt.plot(cumulative_profile, label='linear')