# import from default libraries and packages
import math

import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np


def hour_to_dec(hour_str):
    """ Transforms float hours from HH:MM string format to float with decimal places

    :param hour_str: hour in format HH:MM
    :type hour_str: str

    :return hour_dec: hour in numerical format
    :rtype hour_dec: float

    :example:
    >>> hour_to_dec('02:00')
    2.0
    """

    (H, M) = hour_str.split(':')
    hour_dec = int(H) + int(M) / 60
    return hour_dec


def dec_to_hour(hour_dec):
    """ Transforms float hours with decimal places into HH:MM string format

    :param hour_dec: hour in numerical format
    :type hour_dec: float

    :return hour_str: hour in format HH:MM
    :rtype hour_str: str

    :example:
    >>> dec_to_hour(2.5)
    '02:30'
    """

    (H, M) = divmod(hour_dec * 60, 60)
    hour_str = "%02d:%02d" % (H, M)
    return hour_str


def dec_to_obs(hour_dec, obs_per_hour):
    """  transforms float hours with decimal places into HH:MM string format

    :param hour_dec: hour interval in numerical format
    :type hour_dec: float

    :param obs_per_hour: number of observations per hour
    :type obs_per_hour: int

    :return observations: number of observations
    :rtype observations: int

    :example:
    >>> # 6.30 -> H = 6, M = 30
    >>> #6[hours]*4[observations/hour] + 30[minutes]*1/15[observations/minutes] = 25 [observations]
    >>> dec_to_obs(6.30 , 4)
    25
    """

    (H, M) = divmod(hour_dec * 60, 60)
    observations = int(H * obs_per_hour + M / 15)
    return observations


def roundup(x, digit=1):
    """  rounds number too upper decimal

    :param x: number
    :type x: float

    :param digit: number of digit to round
    :type digit: int

    :return rounded: rounded number
    :rtype rounded: int

    :example:
    >>> roundup(733, digit=10)
    740
    """
    rounded = int(math.ceil(x / digit)) * digit
    return rounded


def nan_diag(matrix):
    """ Transforms a square matrix into a matrix with na on main diagonal

    :param matrix:a matrix of numbers
    :type matrix: np.matrix

    :return matrix_nan: matrix of numbers
    :rtype matrix_nan: np.matrix
    """

    (x, y) = matrix.shape

    if x != y:
        raise RuntimeError("Matrix is not square")

    matrix_nan = matrix.copy()
    matrix_nan[range(x), range(y)] = np.nan
    return matrix_nan


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
