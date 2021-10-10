import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.stats as stats
import seaborn as sns
from kneed import KneeLocator


def boxplot_fun(group, group_cmp_median):
    """ Implements outlier detection through IQR rule and box-plot

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp_median:  is the cmp matrix median by group (i.e., cluster) by column
    :type group_cmp_median: np.ndarray

    :return column: array of same length of group specifying if outlier or not (values 0 and 1)
    :rtype column: np.ndarray

    :return fig: figure of the method
    :rtype fig: plot
    """

    # plot
    fig, ax = plt.subplots()
    bp = ax.boxplot(group_cmp_median, notch=True, patch_artist=True)
    ax.set_ylabel('Distribution of the columns median')
    ax.axes.get_xaxis().set_visible(False)  # remove x-axis
    ax.set_title('Notched box plot')

    # get the outliers
    outliers_both_whisker = [flier.get_ydata() for flier in bp["fliers"]]
    outliers_both_whisker = np.array(outliers_both_whisker)
    outliers = outliers_both_whisker[outliers_both_whisker > np.median(group_cmp_median)]

    # create an array of medians according cluster on yearly period
    median_of_day = np.zeros(group.size)
    j = 0
    for i in range(0, group.size):
        if group[i] == 1:
            median_of_day[i] = group_cmp_median[j]
            j += 1

    # take the outliers
    try:
        threshold = np.min(outliers)
        column = (median_of_day >= threshold)
    except Exception as e:
        print("EXCEPTION in boxplot_fun")
        print(e)
        column = np.zeros(group.size)

    # return a vector of 0/1 int
    column = column.astype(int)
    return column, fig


def zscore_fun(group, group_cmp_median, upper_bound=2):
    """ Implements outlier detection through z-score standardization

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp_median:  is the cmp matrix median by group (i.e., cluster) by column
    :type group_cmp_median: np.ndarray

    :param upper_bound:  upper bount for zscore outlier
    :type upper_bound: float

    :return column: array of same length of group specifying if outlier or not (values 0 and 1)
    :rtype column: np.ndarray

    :return fig: figure of the method
    :rtype fig: plot
    """

    zscore = stats.zscore(group_cmp_median)

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
            j += 1

    # identify outliers depending on the upper bound
    for k in range(group.size):
        if outliers[k] > upper_bound:
            outliers[k] = 1
        else:
            outliers[k] = 0

    # return a vector of 0/1 int
    column = outliers.astype(int)
    return column, fig


def elbow_fun(group, group_cmp_median):
    """ Implements outlier detection through elbow method, the values on the sx of the elbow are labelled as anomaly

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp_median:  is the cmp matrix median by group (i.e., cluster) by column
    :type group_cmp_median: np.ndarray

    :return column: array of same length of group specifying if outlier or not (values 0 and 1)
    :rtype column: np.ndarray

    :return fig: figure of the method
    :rtype fig: plot
    """

    xx = np.array(range(0, group_cmp_median.size))
    yy = np.sort(group_cmp_median)[::-1]  # decreasing
    kn = KneeLocator(xx, yy, curve='convex', direction='decreasing')
    num_anomalies_to_show = kn.knee

    fig, ax = plt.subplots(figsize=(6, 5))
    plt.plot(yy)
    plt.ylabel("Anomaly Score")
    plt.title("Sorted Anomaly Scores")
    plt.axvline(num_anomalies_to_show, ls=":", c="gray")
    anomaly_ticks = list(range(0, group_cmp_median.size, int(group_cmp_median.size / 5)))
    anomaly_ticks.append(num_anomalies_to_show)
    plt.xticks(anomaly_ticks)

    # create an array of medians according cluster on yearly period
    outliers = np.zeros(group.size)

    j = 0
    for i in range(group.size):
        if group[i] == 1:
            outliers[i] = group_cmp_median[j]
            j += 1

    # take the outliers
    anomaly_day = yy[0:num_anomalies_to_show]

    # take the outliers
    try:
        threshold = min(anomaly_day)
        column = (outliers >= threshold)
    except Exception as e:
        print("EXCEPTION in elbow_fun")
        print(e)
        column = np.zeros(group.size)

    # return a vector of 0/1 int
    column = column.astype(int)
    return column, fig


##################
def gesd_test_stat(y, iteration):
    """  This function calculates   Ri = max_i*(x_i-x_bar)/sts_dv(x_i)

    :param y: input_series of ESD_Test ( array of medians)
    :type y: np.ndarray

    :param iteration: n
    :type iteration: int

    :return cal: R_i
    :rtype y: float

    :return max_i: max_i
    :rtype y: int
    """

    std_dev = np.std(y)
    avg_y = np.mean(y)
    abs_val_minus_avg = abs(y - avg_y)
    max_of_deviations = max(abs_val_minus_avg)
    max_ind = np.argmax(abs_val_minus_avg)
    cal = max_of_deviations / std_dev

    # print('Test {}'.format(iteration))
    # print("Test Statistics Value(R{}) : {}".format(iteration, cal))

    return cal, max_ind


def gesd_calculate_critical_value(size, alpha, iteration):  # 1- alpha/(2*(A+1))  A=n-i  B=tp,n-i-1  i=1....r
    """ This function calculates the critical value for the hp test

    :param size: n
    :type size: int

    :param alpha: level of confidence = 0.05
    :type alpha: float

    :param iteration: i
    :type iteration: int

    :return critical_value: lambda_i
    :rtype critical_value: float
    """

    t_dist = stats.t.ppf(1 - alpha / (2 * size), size - 2)  # 1- alpha/(2*(A+1))   A=n-i
    numerator = (size - 1) * np.sqrt(np.square(t_dist))  # A*B B=tp,n-i-1  i=1....r
    denominator = np.sqrt(size) * np.sqrt(size - 2 + np.square(t_dist))
    critical_value = numerator / denominator

    # print("Critical Value(λ{}): {}".format(iteration, critical_value))

    return critical_value


def gesd_esd_test(input_series, alpha, max_outliers):
    """ GESD methods function
    :param input_series: an array holding medians ( variable length, depending on cluster)
    :param alpha: level of confidence , default to 0.05
    :param max_outliers: give the number of outliers expected
    :return: list in the form of df that include (value_i R_i lambda_i) and number of outliers really found
    """

    stats_1 = []
    max_i = 0
    critical_vals = []
    for iterations in range(1, max_outliers + 1):
        stat, max_index = gesd_test_stat(input_series, iterations)
        critical = gesd_calculate_critical_value(len(input_series), alpha, iterations)
        # # check values from function
        # if stat > critical:  # R > C:
        #     print('{} is an outlier. R{} > λ{}: {:.4f} > {:.4f} \n'.format(input_series[max_index], iterations,
        #                                                                    iterations, stat, critical))
        # else:
        #     print(
        #         '{} is not an outlier. R{}> λ{}: {:.4f} > {:.4f} \n'.format(input_series[max_index], iterations,
        #                                                                     iterations, stat, critical))

        input_series = np.delete(input_series, max_index)
        critical_vals.append(critical)
        stats_1.append(stat)
        if stat > critical:
            max_i = iterations

    # print('H0:  there are no outliers in the data')
    # print('Ha:  there are up to 10 outliers in the data')
    # print('')
    # print('Significance level:  α = {}'.format(alpha))
    # print('Critical region:  Reject H0 if Ri > critical value')
    # print('Ri: Test statistic')
    # print('λi: Critical Value')
    # print(' ')
    df = pd.DataFrame({'i': range(1, max_outliers + 1), 'Ri': stats_1, 'λi': critical_vals})

    df.index = df.index + 1

    # print('Number of outliers {}'.format(max_i))

    return max_i


def gesd_fun(group, group_cmp_median):
    """ Implements outlier detection through GESD-test

    :param group: is an 365 length array defining group (values 0 and 1)
    :type group: np.ndarray

    :param group_cmp_median:  is the cmp matrix median by group (i.e., cluster) by column
    :type group_cmp_median: np.ndarray

    :return column: array of same length of group specifying if outlier or not (values 0 and 1)
    :rtype column: np.ndarray

    :return fig: figure of the method
    :rtype fig: plot
    """

    fig, ax = plt.subplots()
    stats.probplot(group_cmp_median, dist="norm", plot=plt)

    n_outliers = gesd_esd_test(group_cmp_median, 0.05, 10)

    # create an array of medians according cluster on yearly period
    medians = np.zeros(group.size)

    j = 0
    for i in range(group.size):
        if group[i] == 1:
            medians[i] = group_cmp_median[j]
            j += 1

    anomaly_day = np.sort(group_cmp_median)[:-(n_outliers + 1):-1]
    try:
        threshold = min(anomaly_day)
        column = (medians >= threshold) * 1
    except Exception as e:
        print("EXCEPTION in gesd_fun")
        print(e)
        column = np.zeros(group.size)

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

    # do the median of the group_cmp matrix to get a vector
    group_cmp_median = np.nanmedian(group_cmp, axis=0)

    column_1, plot_1 = boxplot_fun(group=group, group_cmp_median=group_cmp_median)
    column_2, plot_2 = zscore_fun(group=group, group_cmp_median=group_cmp_median, upper_bound=2.5)
    column_3, plot_3 = elbow_fun(group=group, group_cmp_median=group_cmp_median)
    column_4, plot_4 = gesd_fun(group=group, group_cmp_median=group_cmp_median)

    df = pd.DataFrame()
    df['box-plot'] = pd.Series(column_1.astype(int))
    df['z-score'] = pd.Series(column_2.astype(int))
    df['elbow'] = pd.Series(column_3.astype(int))
    df['gesd'] = pd.Series(column_4.astype(int))

    # majority voting
    df['severity'] = df.sum(axis=1, numeric_only=True)

    # return the severity as ndarray to integrate on main code
    cmp_ad_score = np.asarray(df['severity'])

    return cmp_ad_score


# uncomment when testing / comment when deploying

"""
path_to_data = os.getcwd() + os.sep + 'Polito_Usecase' + os.sep + 'data'
path_to_figures = os.getcwd() + os.sep + 'Polito_Usecase' + os.sep + 'figures'

group_csv = pd.read_csv(path_to_data + os.sep + 'ad_data' + os.sep + "group.csv", header=None)
group_cmp_csv = pd.read_csv(path_to_data + os.sep + 'ad_data' + os.sep + "group_cmp.csv", header=None)

group_array = np.asarray(group_csv[0], dtype=bool)
group_cmp_array = np.asarray(group_cmp_csv)

# nel codice i dati arrivano cosi

cmp_ad_score_result = anomaly_detection(group_array, group_cmp_array)

print("end")
"""
