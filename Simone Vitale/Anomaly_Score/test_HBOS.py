import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

from pyod.models.hbos import HBOS

path_data='plot_cmp_Cluster_5.csv'
data = pd.read_csv(path_data,header=None)

newdata=[None]*(data[0].size -1)
for jj in range(data[0].size -1):
 newdata[jj] = [ii for ii in data[jj] if np.isnan(ii) == False]

hbos = HBOS(n_bins=12)
hbos.fit(newdata)

HBOS(alpha=0.1, contamination=0.1, n_bins=12, tol=0.5)
output = hbos.decision_function(newdata)

hbos.predict(newdata)
