# import from default libraries and packages
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.ticker as mticker
import math


def hour_to_dec(hour):
    """ transforms float hours from HH:MM string format to float with decimal places
    :param hour:
    :return:
    """
    (H, M) = hour.split(':')
    result = int(H) + int(M) / 60
    return result


def dec_to_hour(hour):
    """ transforms float hours with decimal places into HH:MM string format
    :param hour:
    :return:
    """

    H, M = divmod(hour * 60, 60)
    result = "%02d:%02d" % (H, M)
    return result


def roundup(x, digit=1):
    """ rounds number too upper decimal
    :param x:
    :param digit:
    :return:
    """
    return int(math.ceil(x / digit)) * digit


def anomaly_score_calc(group_matrix, group_array):
    """utils function used to calculate anomaly score
    :param group_matrix:
    :param group_array:
    :return:
    """

    # Calculate an anomaly score by summing the values (per type of day) across one axis and averaging
    cmp_group_score_array = np.nansum(group_matrix, axis=1) / np.count_nonzero(group_array)
    return cmp_group_score_array


def nan_diag(matrix):
    """Fills the diagonal of the passed square matrix with nans.
    :param matrix:
    :return:
    """

    h, w = matrix.shape

    if h != w:
        raise RuntimeError("Matrix is not square")

    matrix = matrix.copy()
    matrix[range(h), range(w)] = np.nan
    return matrix


def CMP_plot(contextual_mp,
             palette="viridis",
             title=None,
             xlabel=None,
             legend_label=None,
             extent=None,
             date_ticks=14,
             index_ticks=5
             ):
    """ utils function used to plot the contextual matrix profile

    :param contextual_mp:
    :param palette:
    :param title:
    :param xlabel:
    :param legend_label:
    :param extent:
    :param date_ticks:
    :param index_ticks:
    :return:
    """

    figure = plt.figure()
    axis = plt.axes()

    if extent is not None:
        # no extent dates given
        im = plt.imshow(nan_diag(contextual_mp),
                        cmap=palette,
                        origin="lower",
                        extent=extent
                        )
        # Label layout
        axis.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        axis.yaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        axis.xaxis.set_major_locator(mticker.MultipleLocator(date_ticks))
        axis.yaxis.set_major_locator(mticker.MultipleLocator(date_ticks))
        plt.gcf().autofmt_xdate()

    else:
        # index as
        im = plt.imshow(nan_diag(contextual_mp),
                        cmap=palette,
                        origin="lower",
                        vmin=np.min(contextual_mp),
                        vmax=np.max(contextual_mp)
                        )
        plt.xlabel(xlabel)
        ticks = list(range(0, len(contextual_mp), int(len(contextual_mp) / index_ticks)))
        plt.xticks(ticks)
        plt.yticks(ticks)

    # Create an axes for colorbar. The position of the axes is calculated based on the position of ax.
    # You can change 0.01 to adjust the distance between the main image and the colorbar.
    # You can change 0.02 to adjust the width of the colorbar.
    # This practice is universal for both subplots and GeoAxes.
    plt.title(title)
    cax = figure.add_axes([axis.get_position().x1 + 0.01, axis.get_position().y0, 0.02, axis.get_position().height])
    cbar = plt.colorbar(im, cax=cax)  # Similar to fig.colorbar(im, cax = cax)
    cbar.set_label(legend_label)
