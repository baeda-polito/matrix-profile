import pandas as pd

# load the POLITO dataframe small from csv
df_power = pd.read_csv("/Users/robi/Downloads/df_summer.csv", sep=',', header=None)
df_power.head()

# time window length
w = 96

# perform MP calculation with euclidean distance
mp = stumpy.stump(df_power['Power_total'], w, normalize=False)

# transform the MP into a dataframe and export to csv
pd.DataFrame(mp).to_csv("./data/mp_euclidean.csv")


