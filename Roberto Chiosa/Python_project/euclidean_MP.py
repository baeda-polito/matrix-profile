import pandas as pd
import stumpy
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as dates
from matplotlib.patches import Rectangle
import datetime as dt

# load the dataframe
df_power = pd.read_csv("./data/df_univariate_small.csv")
df_power.head()

w = 96  # time window width

mp = stumpy.stump(df_power['Power_total'], w, normalize=False)

pd.DataFrame(mp).to_csv("./data/mp_euclidean.csv")


plt.rcParams["figure.figsize"] = [20, 6]  # width, height
plt.rcParams['xtick.direction'] = 'out'
