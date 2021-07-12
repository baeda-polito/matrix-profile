import pandas as pd
import stumpy

# load the POLITO dataframe small from csv
df_power = pd.read_csv("./data/df_univariate_small.csv")
df_power.head()

# time window length
w = 96

# perform MP calculation with euclidean distance
mp = stumpy.stump(df_power['Power_total'], w, normalize=False)

# transform the MP into a dataframe and export to csv
pd.DataFrame(mp).to_csv("./data/mp_euclidean.csv")


