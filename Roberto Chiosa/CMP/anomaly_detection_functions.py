import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.stats as stats
import seaborn as sns
from kneed import KneeLocator


def boxplot_fun(group, group_cmp):
    """ Implements outlier detection through IQR rule and box-plot

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp:  is the cmp matrix by group (i.e., cluster)
    :type group_cmp: np.ndarray

    :return column: array of same length of group specifying if outlier or not (values 0 and 1)
    :rtype column: np.ndarray

    :return fig: figure of the method
    :rtype fig: plot
    """

    # get the median of the columns of the matrix
    columns_median = np.nanmedian(group_cmp, axis=0)

    # plot
    fig, ax = plt.subplots()
    bp = ax.boxplot(columns_median, notch=True, patch_artist=True)
    ax.set_ylabel('Distribution of the columns median')
    ax.axes.get_xaxis().set_visible(False)  # remove x-axis
    ax.set_title('Notched box plot')

    # get the outliers
    outliers_both_whisker = [flier.get_ydata() for flier in bp["fliers"]]
    outliers_both_whisker = np.array(outliers_both_whisker)
    outliers = outliers_both_whisker[outliers_both_whisker > np.median(columns_median)]

    # create an array of medians according cluster on yearly period
    median_of_day = np.zeros(group.size)
    j = 0
    for i in range(0, group.size):
        if group[i] == 1:
            median_of_day[i] = columns_median[j]
            j = j + 1

    # take the outliers
    try:
        threshold = np.min(outliers)
        column = (median_of_day >= threshold) * 1
    except:
        column = np.zeros(group.size)

    return column, fig


def zscore_fun(group, group_cmp, upper_bound=2):
    """ Implements outlier detection through z-score standardization

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp:  is the cmp matrix by group (i.e., cluster)
    :type group_cmp: np.ndarray

    :param upper_bound:  upper bount for zscore outlier
    :type upper_bound: float

    :return column: array of same length of group specifying if outlier or not (values 0 and 1)
    :rtype column: np.ndarray

    :return fig: figure of the method
    :rtype fig: plot
    """

    # get the median of the columns of the matrix
    columns_median = np.nanmedian(group_cmp, axis=0)

    zscore = stats.zscore(columns_median)

    fig, ax = plt.subplots()
    sns.kdeplot(data=zscore)
    plt.axvline(x=upper_bound, ymin=0, ymax=1, linestyle='dashed', color='gray')

    # create an array of medians according cluster on yearly period
    outliers = np.zeros(group.size)
    j = 0

    # define vector outliers as same dimensions of group (365)
    for i in range(group.size):
        if group[i] == 1:
            outliers[i] = zscore[j]
            j = j + 1

    # identify outliers depending on the upper bound
    for k in range(group.size):
        if outliers[k] > upper_bound:
            outliers[k] = 1
        else:
            outliers[k] = 0

    column = outliers
    return column, fig


def elbow_fun(group, group_cmp):
    """ Implements outlier detection through elbow method, the values on the sx of the elbow of a curve are labelled as anomaly

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp:  is the cmp matrix by group (i.e., cluster)
    :type group_cmp: np.ndarray

    :return column: array of same length of group specifying if outlier or not (values 0 and 1)
    :rtype column: np.ndarray

    :return fig: figure of the method
    :rtype fig: plot
    """

    columns_median = np.nanmedian(group_cmp, axis=0)  # get the median of the columns

    xx = np.array(range(0, columns_median.size))
    yy = np.sort(columns_median)[::-1]  # decreasing
    kn = KneeLocator(xx, yy, curve='convex', direction='decreasing')
    num_anomalies_to_show = kn.knee

    fig, ax = plt.subplots(figsize=(6, 5))
    plt.plot(yy)
    plt.ylabel("Anomaly Score")
    plt.title("Sorted Anomaly Scores")
    plt.axvline(num_anomalies_to_show, ls=":", c="gray")
    anomaly_ticks = list(range(0, columns_median.size, int(columns_median.size / 5)))
    anomaly_ticks.append(num_anomalies_to_show)
    plt.xticks(anomaly_ticks)

    # create an array of medians according cluster on yearly period
    outliers = np.zeros(group.size)

    j = 0
    for i in range(group.size):
        if group[i] == 1:
            outliers[i] = columns_median[j]
            j = j + 1

    # take the outliers
    anomaly_day = yy[0:num_anomalies_to_show]
    threshold = min(anomaly_day)
    column = (outliers >= threshold) * 1

    return column, fig


def anomaly_detection(group, group_cmp):
    """ This function implements the anomaly detection methods

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp:  is the cmp matrix by group (i.e., cluster)
    :type group_cmp: np.ndarray

    :return cmp_ad_score: array of same length of group specifying the severity
    :rtype cmp_ad_score: np.ndarray

    """
    column_1, plot_1 = boxplot_fun(group=group, group_cmp=group_cmp)
    column_2, plot_2 = zscore_fun(group=group, group_cmp=group_cmp, upper_bound=2.5)
    column_3, plot_3 = elbow_fun(group=group, group_cmp=group_cmp)

    df = pd.DataFrame()
    df['box-plot'] = pd.Series(column_1.astype(int))
    df['z-score'] = pd.Series(column_2.astype(int))
    df['elbow'] = pd.Series(column_3.astype(int))

    # majority voting
    df['severity'] = df.sum(axis=1, numeric_only=True)

    # return the severity as ndarray to integrate on main code
    cmp_ad_score = np.asarray(df['severity'])

    return cmp_ad_score


# uncomment when testing / comment when deploying

import os

path_to_data = os.getcwd() + os.sep + 'Polito_Usecase' + os.sep + 'data'
path_to_figures = os.getcwd() + os.sep + 'Polito_Usecase' + os.sep + 'figures'

group_csv = pd.read_csv(path_to_data + os.sep + 'ad_data' + os.sep + "group.csv", header=None)
group_cmp_csv = pd.read_csv(path_to_data + os.sep + 'ad_data' + os.sep + "group_cmp.csv", header=None)

group_array = np.asarray(group_csv[0], dtype=bool)
group_cmp_array = np.asarray(group_cmp_csv)

# nel codice i dati arrivano cosi

cmp_ad_score = anomaly_detection(group_array, group_cmp_array)
