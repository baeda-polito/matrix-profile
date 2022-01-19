import numpy as np
import pandas as pd

from utils_functions import hour_to_dec


def energy_anomaly_detection(group, data_full, tw, tw_id):
    """
    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param data_full: is the full dataset
    :type data_full: pd.dataframe

    :param tw: is the time window dataframe
    :type tw: pd.dataframe

    :return energy_score: array of same length of group specifying the energy absorbed in the time window
    :rtype energy_score: np.ndarray

    """

    data_tmp = pd.DataFrame(columns=['Date', 'power', 'mindec'])
    data_tmp['Date'] = data_full.index.date
    data_tmp['power'] = data_full['value'].array
    data_tmp['mindec'] = data_full.index.strftime("%H:%M")
    # convert to decimal
    data_tmp = data_tmp.assign(
        mindec=lambda dataframe: dataframe['mindec'].map(
            lambda x: hour_to_dec(x)
        )
    )

    data_tmp['time_window'] = np.where(
        np.logical_and(data_tmp['mindec'] >= hour_to_dec(tw.iloc[tw_id]['from']), data_tmp['mindec'] <= hour_to_dec(
            tw.iloc[tw_id]['to'])), True, False)

    # filter
    data_tmp = data_tmp[data_tmp.time_window == True]
    # calculate energy
    data_tmp_summary = data_tmp.groupby(['Date']).power.agg(sum)

    energy_score = np.asarray(data_tmp_summary)

    return energy_score


if __name__ == '__main__':
    print("Hi")
