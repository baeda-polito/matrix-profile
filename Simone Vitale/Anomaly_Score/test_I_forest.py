# Imports
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from pyod.models.iforest import IForest
from scipy import stats
from scipy import interpolate
from kneed import KneeLocator, DataGenerator as dg

path_data='plot_cmp_Cluster_4.csv'
data = pd.read_csv(path_data,header=None)


# some useful plots
plt.scatter(range(data.shape[0]), np.sort(data[0].values))
plt.xlabel('index')
plt.ylabel('Distance')
plt.title("Sorted distances")
sns.despine()
plt.show()

# Iforest algorithm
vv= np.array([1,30,55,68])
anomaly_matrix=[]
outlier_matrix=[]

for jj in range(data[0].size -1):

 isolation_forest = IsolationForest(n_estimators=100)
 newdata = [ii for ii in data[jj] if np.isnan(ii) == False]
 newdata= np.asarray(newdata)
 isolation_forest.fit(newdata.reshape(-1, 1))
 xx = np.linspace(newdata.min(), newdata.max(), len(newdata)).reshape(-1,1)
 anomaly_score = isolation_forest.decision_function(xx)
 outlier = isolation_forest.predict(xx)

 for kk in range (4):
  if jj == vv[kk] :
   plt.figure(figsize=(10, 7))
   ax1=plt.subplot(2, 1, 1)
   sns.distplot(data[jj])
   plt.title('Distribution of Distances of column %d' % jj)

   ax2=plt.subplot(2, 1, 2,sharex=ax1)
   plt.plot(xx, anomaly_score, label='anomaly score')
   plt.fill_between(xx.T[0], np.min(anomaly_score), np.max(anomaly_score),
                    where=outlier==-1, color='r',
                    alpha=.4, label='outlier region')
   plt.ylabel('anomaly score')
   plt.xlabel ('Distances')
   plt.title('I_forest column %d'%jj)
   plt.legend()
   plt.show()
   kk= kk+1

 anomaly_matrix.append(anomaly_score)
 outlier_matrix.append(outlier)

fig, (ax1, ax2) = plt.subplots(1, 2)
ax1.pcolormesh(anomaly_matrix)

ax2.pcolormesh(outlier_matrix)
plt.show()

bbbb=[None]*(data[0].size -1)
for jj in range(data[0].size-1):
 aaaa=anomaly_matrix[jj]*(outlier_matrix[jj]==-1)
 bbbb[jj]=sum(abs(aaaa))

# some useful plots
cc = list(range(data[0].size -1))
bbbb.sort(reverse= True)
kneedle = KneeLocator(
 cc, bbbb, S=2, curve="convex", direction="decreasing", interp_method="interp1d")
kneedle.plot_knee()
plt.show()



