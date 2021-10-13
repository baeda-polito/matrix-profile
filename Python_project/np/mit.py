import wfdb
import time
import stumpy
import numpy as np
import pickle as pk
import matplotlib.pyplot as plt
from collections import Counter

import utils
from nprofile import NeighborProfile

valid_annotation = ['N', '/', 'A', 'F', 'J', 'L', 'R', 'Q', 'f', 'V', 'j', 'a', 'E', 'e', 'S']

batch_size = 10000

# change parameters here
d = 180
max_sample = 8
ch = 1

def learn_profile(max_sample, ch, d=180):

    for name in list(range(100,125)) + list(range(200,235)):

        if name in [110, 120, 204, 206, 211, 216, 218, 224, 225, 226, 227, 229]: # does not exist
            continue

        print(name)
        record = wfdb.rdrecord('mit-bih/{}'.format(name))
        signal = record.p_signal[:, ch]

        # calculate nn profile
        scales = ["auto", "demean", "zscore"]

        for scale in scales:
            nprofile = NeighborProfile(max_sample=max_sample, scale=scale).fit(signal, d=d)
            p = []
            for i in range(0, len(signal)-d, batch_size):
                Y = utils.subsequences_from_series(signal, range(i, min(i+batch_size, len(signal)-d)), d)
                p += list(nprofile.estimate(Y))
            pk.dump(p, open("mit-bih/profile/np-{}-{}-{}-{}-channel-{}.pk".format(name, d, max_sample, scale, ch), "wb"))

        # calculate m profile
        mp = stumpy.stump(signal, m=d)
        pk.dump(mp, open("mit-bih/profile/mp-{}-{}-channel{}.pk".format(name, d, ch), "wb"))


def mine_subsequences():

    for ch in [1,2]:

        for name in list(range(100,125)) + list(range(200,235)):

            if name in [110, 120, 204, 206, 211, 216, 218, 224, 225, 226, 227, 229]:
                continue

            d = 180

            annotation = wfdb.rdann('mit-bih/{}'.format(name), 'atr')
            samples = []
            symbols = []
            for i, symbol in enumerate(annotation.symbol):
                if symbol in valid_annotation:
                    samples.append(annotation.sample[i])
                    symbols.append(symbol)

            annotation = (np.array(samples), np.array(symbols))

            max_samples = [8, 16, 32, 64]

            for max_sample in max_samples:
                auto = pk.load(open("mit-bih/profile/np-{}-{}-{}-auto-channel{}.pk".format(name, d, max_sample, ch), "rb"))
                demean = pk.load(open("mit-bih/profile/np-{}-{}-{}-demean-channel{}.pk".format(name, d, max_sample, ch), "rb"))
                zscore = pk.load(open("mit-bih/profile/np-{}-{}-{}-zscore-channel{}.pk".format(name, d, max_sample, ch), "rb"))
            

                ranked_symbols = get_annotation(np.array(auto), annotation)
                print(str(name),", ", ch, ", auto-{}, ".format(max_sample), ", ".join(ranked_symbols))

                ranked_symbols = get_annotation(np.array(demean), annotation)
                print(str(name),", ", ch, ", demean-{}, ".format(max_sample), ", ".join(ranked_symbols))

                ranked_symbols = get_annotation(np.array(zscore), annotation)
                print(str(name),", ", ch,  ", zscore-{}, ".format(max_sample), ", ".join(ranked_symbols))

            mp = pk.load(open("mit-bih/profile/mp-{}-{}-channel{}.pk".format(name, d, ch), "rb"))
            ranked_symbols = get_annotation(np.array(mp[:,0]), annotation)
            print(str(name),", ", ch, ", mp, ", ", ".join(ranked_symbols))


def get_annotation(profile, annotation):

    rank = np.argsort(-profile)
    mask = []
    rank_symbols = []
    for i in rank:
        _, idx = utils.find_nearest(annotation[0], i+90)
        if idx not in mask:
            mask.append(idx)
            rank_symbols.append(annotation[1][idx])
    return rank_symbols


if __name__ == "__main__":

    for max_sample in [8, 16, 32, 64]:
        for ch in [1, 2]:
            learn_profile(max_sample, ch)
    mine_subsequences()