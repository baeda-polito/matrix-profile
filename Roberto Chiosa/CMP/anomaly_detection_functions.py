import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


######################## METHOD_1_MEDIAN_BOXPLOT ###########################
def anomaly_detection_boxplot(group, group_cmp):
    """
    :param group: description
    :type group: array

    :param group_cmp: matrix
    :type group_cmp: array

    :return: column array
    :rtype: the return type description
    """

    group = np.array(group).flatten()

    columns_median = np.nanmedian(group_cmp, axis=0)  # get the median of the columns

    fig, ax = plt.subplots()
    bp = ax.boxplot(columns_median, notch=True, patch_artist=True)
    ax.set_ylabel('Distribution of the columns median')
    ax.axes.get_xaxis().set_visible(False)  # remove x-axis
    ax.set_title('Notched box plot')

    outliers_both_whisker = [flier.get_ydata() for flier in bp["fliers"]]  # get the outliers
    outliers_both_whisker = np.array(outliers_both_whisker)
    outliers = outliers_both_whisker[outliers_both_whisker > np.median(columns_median)]
    # create an array of medians according cluster on yearly period
    median_of_day = np.zeros(group.size)
    jj = 0
    for ii in range(group.size):
        if group[ii] == 1 and jj < len(group_cmp):
            median_of_day[ii] = columns_median[jj]
            jj = jj + 1

    # take the outliers
    try:
        threshold = np.min(outliers)
        column = (median_of_day >= threshold) * 1
    except:
        column = np.zeros(group.size)

    return column, fig


def anomaly_detection(group, group_cmp):
    """
    This function implements the anomaly detection methods

    :param group:
    :param group_cmp:
    :return:
    """
    column_1, plot_1 = anomaly_detection_boxplot(group, group_cmp)

    df = pd.DataFrame()
    df['box-plot'] = pd.Series(column_1.astype(int))

    # majority voting
    df['severity'] = df.sum(axis=1, numeric_only=True)

    # return the severity as ndarray to integrate on main code
    cmp_ad_score = np.asarray(df['severity'])
    return cmp_ad_score


#
## group
# useful paths
path_to_data = os.getcwd() + os.sep + 'Polito_Usecase' + os.sep + 'data'
path_to_figures = os.getcwd() + os.sep + 'Polito_Usecase' + os.sep + 'figures'

group_csv = pd.read_csv(path_to_data + os.sep + 'ad_data' + os.sep + "group.csv", header=None)
group_cmp_csv = pd.read_csv(path_to_data + os.sep + 'ad_data' + os.sep + "group_cmp.csv", header=None)

group_array = np.asarray(group_csv[0], dtype=bool)
group_cmp_array = np.asarray(group_cmp_csv)

# nel codice i dati arrivano cosi

cmp_ad_score = anomaly_detection(group_array, group_cmp_array)
