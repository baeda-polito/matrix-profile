import random
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import stumpy

d=4
ith_distance_profile = np.ndarray((4,7),buffer=np.array([[0.4, 0.2, 0.6, 0.5, 0.2, 0.1, 0.9],
[0.7, 0.0, 0.2, 0.6, 0.1, 0.2, 0.9],
[0.6, 0.7, 0.1, 0.5, 0.8, 0.3, 0.4],
[0.7, 0.4, 0.3, 0.1, 0.2, 0.1, 0.7]]), dtype=np.float64)

ith_matrix_profile = np.full(d, np.inf)
ith_indices = np.full(d, -1, dtype=np.int64)

for k in range(1, d+1):
 smallest_k = np.partition(ith_distance_profile, (k-1), axis=0)[:k] # retrieves the smallest k values in each column
 averaged_smallest_k = smallest_k.mean(axis=0)
 min_val = averaged_smallest_k.min()


 if min_val < ith_matrix_profile[k - 1]:
    ith_matrix_profile[k - 1] = min_val
    ith_indices[k - 1] = averaged_smallest_k.argmin()