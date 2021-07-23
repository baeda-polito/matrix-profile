# import from default libraries and packages
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.ticker as mticker
import pandas as pd
import os

# import from the local module distancematrix
from distancematrix.calculator import AnytimeCalculator
# from distancematrix.generator import ZNormEuclidean
from distancematrix.generator import Euclidean
from distancematrix.consumer import MatrixProfileLR, ContextualMatrixProfile
from distancematrix.consumer.contextmanager import GeneralStaticManager

from matplotlib import rc  # font plot
from kneed import KneeLocator  # find knee of curve

# useful paths
path_to_data = 'Polito_Usecase/data/'
path_to_figures = 'Polito_Usecase/figures1/'
color_palette = 'viridis'

# figures variables
dpi_resolution = 300
fontsize = 10
# plt.style.use("seaborn-paper")
rc('font', **{'family': 'serif', 'serif': ['Georgia']})
plt.rcParams.update({'font.size': fontsize})


# rc('text', usetex=False)


def CMP_plot(contextual_mp,
             palette="viridis",
             title=None,
             xlabel=None,
             legend_label=None,
             extent=None,
             date_ticks=14,
             index_ticks=5
             ):
    """
    utils function used to plot the contextual matrix profile

    :param contextual_mp:
    :param extent:
    :param palette:
    :param title:
    :param xlabel:
    :param legend_label:
    :param date_ticks:
    :param index_ticks:
    :return:
    """

    figure = plt.figure()
    axis = plt.axes()

    if extent is not None:
        # no extent dates given
        im = plt.imshow(contextual_mp,
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
        im = plt.imshow(contextual_mp,
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


########################################################################################
# load dataset
data = pd.read_csv(path_to_data + "polito.csv", index_col='timestamp', parse_dates=True)
obs_per_day = 96
obs_per_hour = 4

# print dataset main characteristics
print(' POLITO CASE STUDY\n',
      '*********************\n',
      'Electrical Load dataset from Substation C\n',
      '- From\t', data.index[0], '\n',
      '- To\t', data.index[len(data) - 1], '\n',
      '-', len(data), 'observations every 15 min\n',
      '-', obs_per_day, '\t observations per day\n',
      '-', obs_per_hour, '\t observations per hour\n'
      )

# Visualise the data
plt.figure(figsize=(10, 4))

plt.subplot(2, 1, 1)
plt.title("Total Electrical Load (complete)")
plt.plot(data)
plt.ylabel("Power [kW]")
plt.gca().set_ylim([0, 850])
plt.gca().set_yticks([0, 200, 400, 600, 800])

plt.subplot(2, 1, 2)
plt.title("Total Electrical Load (first two weeks)")
plt.plot(data.iloc[:4 * 24 * 7 * 2])
plt.ylabel("Power [kW]")
plt.gca().set_ylim([0, 850])
plt.gca().set_yticks([0, 200, 400, 600, 800])

plt.gca().xaxis.set_major_locator(mdates.DayLocator([1, 8, 15]))
plt.gca().xaxis.set_minor_locator(mdates.DayLocator())
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))

plt.grid(b=True, axis="x", which='both', color='black', linestyle=':')

position_x = 6  # position of day labels on x axis
position_y = 750  # position of day labels on y axis

# add day labels on plot
for i in range(14):
    timestamp = data.index[position_x + i * obs_per_day]
    plt.text(timestamp, position_y, timestamp.day_name()[:3])

plt.tight_layout()

# save figure to plot directories
plt.savefig(path_to_figures + "polito.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Define configuration for the Contextual Matrix Profile calculation.
# wewant to find all the subsequences that start from 00:00 to 02:00 (2 hours) and covers the whole day
# in order to avoid overlapping we define the window length as the whole day of observation minus the context length

# context time window length (hours)
m_context = 2

# time window length 96 observations - 4 observation/hour * 2 hours = 88 observations = 22 hours
m = obs_per_day - obs_per_hour * m_context

# Each context starts between 0 and 2 AM (m_context = 2 hours), and lasts 22 hours (m = 88 observations)
contexts = GeneralStaticManager(
    [range(x * obs_per_day, (x * obs_per_day) + obs_per_hour * m_context) for x in range(len(data) // obs_per_day)])

calc = AnytimeCalculator(m, data.values.T)

# Add generator
# - OPTION 1
# distance_string = 'Znormalized Euclidean Distance'
# calc.add_generator(0, ZNormEuclidean())
# - OPTION 2
distance_string = 'Not Normalized Euclidean Distance'
calc.add_generator(0, Euclidean())

# We want to calculate CMP initialize element
cmp = calc.add_consumer([0], ContextualMatrixProfile(contexts))

# We want to calculate MP initialize element
mp = calc.add_consumer([0], MatrixProfileLR())

# Calculate Matrix Profile and Contextual Matrix Profile
calc.calculate_columns()

########################################################################################
# Visualise the whole CMP

# calculate the date labels to define the extent of figure
date_labels = mdates.date2num(data.index[::m].values)

# plot CMP as matrix
plt.figure(figsize=(10, 10))

extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
CMP_plot(contextual_mp=cmp.distance_matrix,
         palette=color_palette,
         title='Contextual Matrix Profile',
         extent=extents,
         legend_label=distance_string,
         date_ticks=14 * 2
         )

plt.savefig(path_to_figures + "polito_cmp1.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Create boolean arrays to indicate whether each day is a weekday/weekend/saturday/sunday
# - holiday (calendar holidays and academic calendar closures)
# - saturdays (not holidays not working days)
# - workingdays (not holiday and not saturdays)

# load data
annotation_df = pd.read_csv(path_to_data + "polito_holiday.csv", index_col='timestamp', parse_dates=True)

# set labels
day_labels = data.index[::obs_per_day]
print("Dataset contains", len(day_labels), "days")

# get number of groups
n_group = annotation_df.shape[1]

for i in range(n_group):
    # get group name from dataframe
    group_name = annotation_df.columns[i]

    # if directory doesnt exists create and save into it

    if not os.path.exists(path_to_figures + group_name):
        os.makedirs(path_to_figures + group_name)

    # greate empty group vector
    group = np.array(annotation_df.T)[i]
    # get cmp from previously computed cmp
    group_cmp = cmp.distance_matrix[:, group][group, :]
    # substitute inf with zeros
    group_cmp[group_cmp == np.inf] = 0
    group_dates = data.index[::obs_per_day].values[group]


    # Calculate an anomaly score by summing the values (per type of day) across one axis and averaging
    cmp_group_score = np.nansum(group_cmp, axis=1) / np.count_nonzero(group)

    # Merge the scores for all types of day into one array
    cmp_ad_score = np.zeros(len(cmp.distance_matrix))*np.nan
    cmp_ad_score[group] = cmp_group_score
    # Ordering of all days, from most to least anomalous
    ad_order = np.argsort(cmp_ad_score)[::-1]
    # move na at the end of the vector
    ad_order = np.roll(ad_order, -np.count_nonzero(np.isnan(cmp_ad_score)))

    # set number of aomalies to show as the elbow of the curve
    # x_ad = np.array(range(0, len(cmp_ad_score)))
    # y_ad = cmp_ad_score[ad_order]
    # kn = KneeLocator(x_ad, y_ad, curve='convex', direction='decreasing')
    # num_anomalies_to_show = kn.knee
    num_anomalies_to_show = 5

    # plot CMP as matrix
    plt.figure(figsize=(7, 7))

    CMP_plot(contextual_mp=group_cmp,
             palette=color_palette,
             title="Power CMP (" + group_name + " only)",
             xlabel=group_name + " Index",
             legend_label=distance_string
             )
    plt.savefig(path_to_figures + group_name + "/polito_cmp.png", dpi=dpi_resolution, bbox_inches='tight')

    # Plot the anomaly scores and our considered threshold
    plt.figure(figsize=(7, 7))
    plt.title("Sorted Anomaly Scores (" + group_name + " only)")
    plt.plot(cmp_ad_score[ad_order])

    plt.ylabel("Anomaly Score")
    plt.axvline(num_anomalies_to_show, ls=":", c="gray")
    anomaly_ticks = list(range(0, len(cmp_ad_score), int(len(cmp_ad_score) / 5)))
    anomaly_ticks.append(num_anomalies_to_show)
    plt.xticks(anomaly_ticks)
    plt.savefig(path_to_figures + group_name + "/polito_anomaly_score.png", dpi=dpi_resolution, bbox_inches='tight')

    # Visualise the top anomalies according to the CMP
    fig, ax = plt.subplots(num_anomalies_to_show, 2, sharex=True, sharey=True, figsize=(10, 14),
                           gridspec_kw={'wspace': 0., 'hspace': 0.})

    ax[0, 0].set_title("Anomaly vs all")
    ax[0, 1].set_title("Anomaly vs " + group_name)

    for j in range(num_anomalies_to_show):
        anomaly_index = ad_order[j]
        anomaly_range = range(obs_per_day * anomaly_index, obs_per_day * (anomaly_index + 1))
        date = day_labels[anomaly_index]

        line_style = "-"

        ax[j, 0].plot(data.values.reshape((-1, obs_per_day)).T, c="gray", alpha=0.07)
        ax[j, 0].plot(data.values[anomaly_range], c="red", linestyle=line_style)
        ax[j, 0].set_ylim([0, 850])
        ax[j, 0].set_yticks([0, 200, 400, 600, 800])

        ax[j, 1].plot(data.values.reshape((-1, obs_per_day))[group].T, c="gray", alpha=0.07)
        ax[j, 1].plot(data.values[anomaly_range], c="red", linestyle=line_style)
        ax[j, 1].set_ylim([0, 850])
        ax[j, 1].set_yticks([0, 200, 400, 600, 800])

        ax[j, 0].text(0, position_y, "CMP-Anomaly " + str(j + 1))
        ax[j, 1].text(0, position_y, date.day_name() + " " + str(date)[:10])

    ax[0, 0].set_xticks(range(0, 97, 24))
    ticklabels = ["{hour}:00".format(hour=(x // obs_per_hour)) for x in range(0, 97, 24)]
    ticklabels[-1] = ""
    ax[0, 0].set_xticklabels(ticklabels)

    plt.tight_layout()

    ax[num_anomalies_to_show // 2, 0].set_ylabel("Power [kW]")
    ax[num_anomalies_to_show - 1, 1].set_xlabel("Time of day")

    plt.savefig(path_to_figures + group_name + "/polito_anomalies.png", dpi=dpi_resolution,
                bbox_inches='tight')
