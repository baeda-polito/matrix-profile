## import
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
import seaborn as sns
from GESD_function import ESD_Test
from kneed import KneeLocator
from scipy import stats


######################## METHOD_1_MEDIAN_BOXPLOT ###########################
def boxplot_fun(group, group_cmp):
    '''
    This function helps to analyze data through box-plot
    :param group: is an array of length 365 holding cluster membership through values 0 and 1
    :param group_cmp: is the cmp by cluster
    :return: this function will return an outliers array in the form( true or false) and a figure
    '''

    group = np.array(group).flatten()

    columns_median = np.nanmedian(group_cmp, axis=0)  # get the median of the columns

    fig_1, ax = plt.subplots()
    bp = ax.boxplot(columns_median, notch=True, patch_artist=True)
    ax.set_ylabel('Distribution of the columns median')
    ax.axes.get_xaxis().set_visible(False)  # remove x-axis
    ax.set_title('Notched box plot')


    outliers_both_whiskers = [flier.get_ydata() for flier in bp["fliers"]]  # get the outliers
    outliers_both_whiskers=np.array(outliers_both_whiskers)
    outliers= outliers_both_whiskers[outliers_both_whiskers > np.median(columns_median)]


    # create an array of medians according cluster on yearly period
    median_of_day = np.zeros(group.size)
    jj = 0
    for ii in range(group.size):
        if group[ii] == 1 and jj < (len(group_cmp)):
            median_of_day[ii] = columns_median[jj]
            jj = jj + 1

    # take the outliers
    threshold = np.min(outliers)
    column_1 = (median_of_day >= threshold) * 1

    return (column_1, fig_1)


######################## METHOD_2_ZSCORE-MEDIAN ###########################

def zscore_fun(group,group_cmp):
   '''
   This function helps to analyze data through z-score trasformation
   :param group: is an array of length 365 holding cluster membership through values 0 and 1
   :param group_cmp: is the cmp by cluster
   :return: this function will return an outliers array in the form( true or false) and a figure
   '''

    group = np.array(group).flatten()
    columns_median = np.nanmedian(group_cmp, axis=0)  # get the median of the columns
    zscore = stats.zscore(columns_median)

    upper_bound = 2

    fig_2, ax = plt.subplots()
    sns.kdeplot(data=zscore)
    plt.axvline(x=upper_bound, ymin=0, ymax=1, linestyle='dashed', color='gray')

    # create an array of medians according cluster on yearly period
    outliers = np.zeros(group.size)
    jj = 0

    for ii in range(group.size):
        if group[ii] == 1 and jj < (len(group_cmp)):
            outliers[ii] = zscore[jj]
            jj = jj + 1

    for kk in range(group.size):
        if outliers[kk] > upper_bound:
            outliers[kk] = 1
        else:
            outliers[kk] = 0

    # take the outliers
    column_2 = outliers

    # in the worst case scenario column_2 is a zero array, it doesn't need try except controll!
    return(column_2, fig_2)

######################## METHOD_3_ELBOW ###########################
def elbow_fun(group, group_cmp):
    '''
    This function helps to analyze data elbow-methods: the values below the elbow of a curve are labelled as anomaly
    :param group: is an array of length 365 holding cluster membership through values 0 and 1
    :param group_cmp: is the cmp by cluster
    :return: this function will return an outliers array in the form( true or false) and a figure
    '''

    group = np.array(group).flatten()

    columns_median = np.nanmedian(group_cmp, axis=0)  # get the median of the columns

    xx = np.array(range(0, columns_median.size))
    yy = np.sort(columns_median)[::-1]  # decreasing
    kn = KneeLocator(xx, yy, curve='convex', direction='decreasing')
    num_anomalies_to_show = kn.knee

    fig_3, ax = plt.subplots(figsize=(6, 5))
    plt.plot(yy)
    plt.ylabel("Anomaly Score")
    plt.title("Sorted Anomaly Scores")
    plt.axvline(num_anomalies_to_show, ls=":", c="gray")
    anomaly_ticks = list(range(0, columns_median.size, int(columns_median.size / 5)))
    anomaly_ticks.append(num_anomalies_to_show)
    plt.xticks(anomaly_ticks)

    # create an array of medians according cluster on yearly period
    medians = np.zeros(group.size)

    jj = 0
    for ii in range(group.size):
        if group[ii] == 1 and jj < (len(group_cmp)):
            medians[ii] = columns_median[jj]

            jj = jj + 1

    # take the outliers

    anomaly_day = yy[0:num_anomalies_to_show]

    threshold = min(anomaly_day)
    column_3 = (outliers >= threshold) * 1

    try:
     threshold = min(anomaly_day)
     column_3= (medians >= threshold)*1

    except:
        column_3 = np.zeros(group.size)
        column_3 = column_3.astype(int)

    return (column_3, fig_3)

######################## METHOD_4_GESD ###########################
def gesd_fun(group,group_cmp):
    '''
    This function helps to detect outliers through GESD-test:
    :param group: is an array of length 365 holding cluster membership through values 0 and 1
    :param group_cmp: is the cmp by cluster
    :return: this function will return an outliers array in the form( true or false) and a figure
    '''

    group = np.array(group).flatten()

    columns_median = np.nanmedian(group_cmp, axis=0)  # get the median of the columns

    fig_4, ax = plt.subplots()
    stats.probplot(columns_median, dist="norm", plot=plt)
    plt.show()

    GESD_df, n_outliers = ESD_Test(columns_median, 0.05, 10)

    # create an array of medians according cluster on yearly period
    medians = np.zeros(group.size)

    jj = 0
    for ii in range(group.size):
        if group[ii] == 1 and jj < (len(group_cmp)):
            medians[ii] = columns_median[jj]

            jj = jj + 1

    anomaly_day = np.sort(columns_median)[:-(n_outliers + 1):-1]
    try:
     threshold = min(anomaly_day)
     column_4 = (medians >= threshold) * 1

    except:
        column_4 = np.zeros(group.size)
        column_4 = column_4.astype(int)

    return (column_4, fig_4)
