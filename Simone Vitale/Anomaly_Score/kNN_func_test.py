def anomaly_function(data):
 import numpy as np
 from sklearn.neighbors import NearestNeighbors

 data = [data[ii][~np.isnan(data[ii])] for ii in range(data[0].size)]
 median_distance = []

 k = 10  # number of k-neighbor

 for jj in range(data[0].size+1):
     knn = NearestNeighbors(n_neighbors=k, metric='euclidean') # initialize algorithm
     column = data[jj].reshape(-1, 1)
     knn.fit(column)                                           # add data
     neighbors_and_distances = knn.kneighbors(column)          # Gather the kth nearest neighbor distance
     knn_distances = neighbors_and_distances[0]
     tnn_distance = np.mean(knn_distances, axis=1)             # Gather the average distance to each points nearest neighbor
     neighbors = neighbors_and_distances[1]
     kth_distance = [x[-1] for x in knn_distances]
     median_distance.append(np.median(tnn_distance))           # get the median of distances

 median_distance = np.array(median_distance)
 return median_distance;
