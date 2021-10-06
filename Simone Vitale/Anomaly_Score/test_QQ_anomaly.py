import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.stats as stats

"""
SUPPORTO
"""
path_data='plot_cmp_Cluster_4.csv'
path_data_cluster='/Users/simonevitale/Desktop/matrix-profile/Roberto Chiosa/CMP/Polito_Usecase/data/'

cluster_df=pd.read_csv(path_data_cluster+'group_cluster.csv', index_col='timestamp', parse_dates=True)
data = pd.read_csv(path_data,header=None)
data=np.array(data)

"""
# FUNZIONE
"""
median_columns=np.array([])
for ii in range(data[0].size):
 nan_column = data[:,ii][~np.isnan(data[:,ii])]
 median_columns=np.append(median_columns,np.median(nan_column))

zscore=stats.zscore(median_columns)
