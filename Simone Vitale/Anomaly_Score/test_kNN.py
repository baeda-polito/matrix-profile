import numpy as np
import matplotlib.pyplot as plt
import pandas as pd


from sklearn.neighbors import NearestNeighbors
from kneed import KneeLocator

path_data='plot_cmp_Cluster_4.csv'

data = pd.read_csv(path_data,header=None)
data=[data[ii].dropna() for ii in range(data[0].size)]
median_distance=[]

k = 10 #number of k-neighbor

for jj in range(data[0].size):

 knn = NearestNeighbors(n_neighbors=k, metric='euclidean') #initialize algorithm
 column=data[jj].to_numpy().reshape(-1,1)
 knn.fit(column)                                           #add data
 neighbors_and_distances = knn.kneighbors(column)          # Gather the kth nearest neighbor distance
 knn_distances = neighbors_and_distances[0]
 tnn_distance = np.mean(knn_distances, axis=1)             # Gather the average distance to each points nearest neighbor
 neighbors = neighbors_and_distances[1]
 kth_distance = [x[-1] for x in knn_distances]


 fig,(ax,ax1)=plt.subplots(1,2)
 ax.scatter(range(data[0].size), tnn_distance)
 ax.set_title('Day_'+str(jj))
 ax.set_xlabel('days')
 ax.set_ylabel('knn-average distances(day '+str(jj)+' vs other days)')
 ax1.boxplot( tnn_distance)
 ax1.axes.get_xaxis().set_visible(False) #remove x-axis
 plt.show()

 median_distance.append(np.median(tnn_distance))           #get the median of distances


median_distance=np.array(median_distance)
median_distance=np.sort(median_distance)
median_distance= median_distance[::-1]

kneedle = KneeLocator(
 range(median_distance.size),median_distance, S=1, curve="convex", direction="decreasing", interp_method="interp1d")

plt.plot(range(median_distance.size), median_distance)
plt.vlines(kneedle.knee, median_distance.min(), median_distance.max(), color='grey', linestyles=':')
plt.ylabel("Anomaly Score")
plt.title("Sorted Anomaly Scores")
plt.show()




