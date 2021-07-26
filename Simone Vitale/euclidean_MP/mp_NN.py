import random
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import stumpy

# load the POLITO dataframe small from csv
df_power = pd.read_csv("./data/df_two_months.csv")

w=96
kk = 3

#compute distance profile
T_df=df_power['Power_total']

cumulative_profile = [0 for ii in range(len(df_power)-w+1)]

Q_df_1 = df_power['Power_total'][0:(w-1)]
cumulative_profile[0]=0

for jj in range((len(df_power)-w+1)):

  distance_profile = stumpy.core.mass(Q_df_1, T_df)

  # find the idxs of the k-st NN

  index_0 = np.where(distance_profile < 1/2)
  excl_zone = int(np.ceil(w / 4))
  zone_start = max(0,index_0[0][0] - excl_zone)
  zone_end = min(5761,index_0[0][0] + excl_zone + 1 ) # Notice that we add one since this is exclusive
  distance_profile[zone_start: zone_end] = np.inf

  idxs = np.argpartition(distance_profile, kk)[-(kk+1):-1]
  #idxs = idxs[np.argsort(distance_profile[idxs])]

  # take the 3-NN
  idx=random.randint(0,5761)
  Q_df_2 = df_power['Power_total'][(0+idx):((w-1)+idx)]
  cumulative_profile[jj]=sum(Q_df_1)-sum(Q_df_2)

  Q_df_1=df_power['Power_total'][(0+idx):((w-1)+idx)]

  #print(f"The second nearest neighbor to `Q_df` is located at idxs {idxs}  in `T_df`")

plt.plot(cumulative_profile, label='linear')
plt.show()