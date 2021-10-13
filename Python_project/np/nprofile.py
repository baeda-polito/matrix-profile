import numpy as np
from sklearn.utils import check_random_state, random
from scipy.spatial import distance
from sklearn.preprocessing import scale as sk_scale

import warnings

class NeighborProfile():

    def __init__(self,
                 n_nnballs=100, 
                 max_sample=8, 
                 random_state=None,
                 scale="auto"):
        self.n_nnballs = n_nnballs
        self.max_sample = max_sample
        self.random_state = random_state
        self.scale = scale
        
    def fit(self, T, d):
        rnd = check_random_state(self.random_state)
        l = len(T)
        self.d = d

        # construct nn balls
        self.list_of_nn_ball = []
        for _ in range(self.n_nnballs):
            seq_idx = random.sample_without_replacement(l-d+1, self.max_sample, random_state=rnd)
            X = _construct_array(T, seq_idx, d)
            X = _scale(X, scale=self.scale)
            triu = distance.pdist(X)

            distance_matrix = np.zeros((self.max_sample, self.max_sample))
            distance_matrix[np.triu_indices(self.max_sample, 1)] = triu
            distance_matrix += distance_matrix.T
            distance_matrix += np.max(triu) * np.eye(self.max_sample)

            nn_distance = np.min(distance_matrix, axis=0)
            nn_ball = (X, nn_distance)
            self.list_of_nn_ball.append(nn_ball)
        
        return self

    def estimate_for_time_series(self, T, batchsize = 10000):
        profile = []
        for i in range(0, len(T)-self.d, batchsize):
            Y = _subsequences_from_series(T, range(i, min(i+batchsize, len(T)-self.d)), self.d)
            profile += list(self.estimate_for_subsequences(Y))
        return profile
 

    def estimate_for_subsequences(self, Y):
        Y = _scale(Y, self.scale)
        r_list = []
        for _, nn_ball in enumerate(self.list_of_nn_ball):
            nnball_c, nnball_r = nn_ball[0], nn_ball[1]
            cdist = distance.cdist(Y, nnball_c)
            nn_d_idx = cdist.argmin(axis=1)
            nn_d = cdist.min(axis=1)
            
            invalid_idx = nnball_r[nn_d_idx] < nn_d
            nn_r = nnball_r[nn_d_idx]
            nn_r[invalid_idx] = nn_d[invalid_idx]
            
            r_list.append(np.log(nn_r))
        
        profile = np.mean(r_list, axis=0)
        return profile


def _subsequences_from_series(ts, idx, d):
    X = np.empty((len(idx), d))
    for i in range(len(idx)):
        X[i, :] = ts[idx[i]:idx[i]+d]
    return X

def _construct_array(T, idx, d):
    X = np.empty((len(idx), d))
    for i, s in enumerate(idx):
        X[i, :] = T[s:s+d]
    return X

def _scale(X, scale):
    if scale == "auto":
        return X

    if scale == "demean":
        return sk_scale(X, axis=1, with_std=False)

    if scale == "zscore":
        return sk_scale(X, axis=1)
