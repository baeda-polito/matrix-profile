import pandas as pd
from matplotlib import pyplot as plt
import numpy as np
import matrixprofile as mp

df_power = pd.read_csv("./data/df_univariate_small.csv")

vals = np.asarray(df_power['Power_total'])

fig, ax = plt.subplots(figsize=(20, 10))
ax.plot(np.arange(len(vals)), vals, label='Test Data')

profile, figures = mp.analyze(vals)

figures[1].show()
