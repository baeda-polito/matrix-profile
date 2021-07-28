# import from default libraries and packages
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
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
from utils_functions import roundup, anomaly_score_calc, CMP_plot, hour_to_dec, dec_to_hour, nan_diag

# useful paths
path_to_data = 'Polito_Usecase/data/'
path_to_figures = 'Polito_Usecase/figures/'
color_palette = 'viridis'

# figures variables
dpi_resolution = 300
fontsize = 10

# plt.style.use("seaborn-paper")
rc('font', **{'family': 'serif', 'serif': ['Georgia']})
plt.rcParams.update({'font.size': fontsize})

########################################################################################
# load dataset
data = pd.read_csv(path_to_data + "polito.csv", index_col='timestamp', parse_dates=True)
obs_per_day = 96
obs_per_hour = 4

min_power = 0  # minimum value of power
max_power = 850  # max(data.values) # maximum value of power
ticks_power = list(range(min_power, max_power, roundup(max_power / 6, digit=100)))

position_x = 6  # position of day labels on x axis
position_y = 750  # position of day labels on y axis

# print dataset main characteristics
print(' POLITO CASE STUDY\n',
      '*********************\n',
      'Electrical Load dataset from Substation C\n',
      '- From\t', data.index[0], '\n',
      '- To\t', data.index[len(data) - 1], '\n',
      '-', len(data.index[::obs_per_day]), '\tdays\n',
      '- 1 \tobservations every 15 min\n',
      '-', obs_per_day, '\tobservations per day\n',
      '-', obs_per_hour, '\tobservations per hour\n',
      '-', len(data), 'observations\n'
      )

# Visualise the data
plt.figure(figsize=(10, 4))

plt.subplot(2, 1, 1)
plt.title("Total Electrical Load (complete)")
plt.plot(data)
plt.ylabel("Power [kW]")
plt.gca().set_ylim([min_power, max_power])
plt.gca().set_yticks(ticks_power)

plt.subplot(2, 1, 2)
plt.title("Total Electrical Load (first two weeks)")
plt.plot(data.iloc[:4 * 24 * 7 * 2])
plt.ylabel("Power [kW]")
plt.gca().set_ylim([min_power, max_power])
plt.gca().set_yticks(ticks_power)

plt.gca().xaxis.set_major_locator(mdates.DayLocator([1, 8, 15]))
plt.gca().xaxis.set_minor_locator(mdates.DayLocator())
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))

plt.grid(b=True, axis="x", which='both', color='black', linestyle=':')

# add day labels on plot
for i in range(14):
    timestamp = data.index[position_x + i * obs_per_day]
    plt.text(timestamp, position_y, timestamp.day_name()[:3])

plt.tight_layout()

# save figure to plot directories
plt.savefig(path_to_figures + "polito.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Define configuration for the Contextual Matrix Profile calculation.
time_window = pd.read_csv(path_to_data + "time_window.csv")

# CONTEXT: DATA DRIVEN
m = time_window["observations"][1]  # data driven
m_context = 2
context_end = int(hour_to_dec(time_window["from"][1]))  # [hours]
context_start = context_end - m_context

# # CONTEXT: USER DEFINED
# # We want to find all the subsequences that start from 00:00 to 02:00 (2 hours) and covers the whole day
# # In order to avoid overlapping we define the window length as the whole day of observation minus the context length.
#
# # - Beginning of the context 00:00 AM [hours]
# context_start = 17
#
# # - End of the context 02:00 AM [hours]
# context_end = 19
#
# # - Context time window length 2 [hours]
# m_context = context_end - context_start  # 2
#
# # - Time window length [observations]
# # m = 96 [observations] - 4 [observation/hour] * 2 [hours] = 88 [observations] = 22 [hours]
# # m = obs_per_day - obs_per_hour * m_context
# m = 20 # with guess

# context string to explain
context_string = 'Subsequences of ' + dec_to_hour(m / obs_per_hour) + ' h that starts between ' + dec_to_hour(
    context_start) + ' and ' + dec_to_hour(context_end)
print('Context: ' + context_string)

# context string for names
context_string_small = 'ctx_from' + dec_to_hour(
    context_start) + '_to' + dec_to_hour(context_end) + "_m" + dec_to_hour(m / obs_per_hour)

# if figures directory doesnt exists create and save into it
if not os.path.exists(path_to_figures + context_string_small):
    os.makedirs(path_to_figures + context_string_small)

# Context Definition:
contexts = GeneralStaticManager([
    range(
        # FROM  [observations]  = x * 96 [observations] + 0 [hour] * 4 [observation/hour]
        (x * obs_per_day) + context_start * obs_per_hour,
        # TO    [observations]  = x * 96 [observations] + (0 [hour] + 2 [hour]) * 4 [observation/hour]
        (x * obs_per_day) + (context_start + m_context) * obs_per_hour)
    for x in range(len(data) // obs_per_day)
])

########################################################################################
# Calculate Contextual Matrix Profile
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
calc.calculate_columns(print_progress=True)

# calculate the date labels to define the extent of figure
date_labels = mdates.date2num(data.index[::m].values)

# plot CMP as matrix

# save for R plot
np.savetxt(path_to_data + 'plot_cmp_full.csv', nan_diag(cmp.distance_matrix), delimiter=",")

plt.figure(figsize=(10, 10))

extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
CMP_plot(contextual_mp=cmp.distance_matrix,
         palette=color_palette,
         title='Contextual Matrix Profile',
         extent=extents,
         legend_label=distance_string,
         date_ticks=14 * 2
         )

plt.savefig(path_to_figures + context_string_small + os.sep + "polito_cmp1.png",
            dpi=dpi_resolution,
            bbox_inches='tight')

########################################################################################
# Create boolean arrays to indicate whether each day is a weekday/weekend/saturday/sunday
# - holiday (calendar holidays and academic calendar closures)
# - saturdays (not holidays not working days)
# - workingdays (not holiday and not saturdays)

# load data
annotation_df = pd.read_csv(path_to_data + "polito_holiday.csv", index_col='timestamp', parse_dates=True)

# set labels
day_labels = data.index[::obs_per_day]

# get number of groups
n_group = annotation_df.shape[1]
i=3
for i in range(n_group):
    # get group name from dataframe
    group_name = annotation_df.columns[i]

    # if figures directory doesnt exists create and save into it
    if not os.path.exists(path_to_figures + context_string_small + os.sep + group_name):
        os.makedirs(path_to_figures + context_string_small + os.sep + group_name)

    # greate empty group vector
    group = np.array(annotation_df.T)[i]
    # get cmp from previously computed cmp
    group_cmp = cmp.distance_matrix[:, group][group, :]
    # substitute inf with zeros
    group_cmp[group_cmp == np.inf] = 0
    # get dates
    group_dates = data.index[::obs_per_day].values[group]

    # save for R plot
    np.savetxt(path_to_data + 'plot_cmp_'+group_name+'.csv', nan_diag(group_cmp), delimiter=",")

    # plot CMP as matrix
    plt.figure(figsize=(7, 7))

    CMP_plot(contextual_mp=group_cmp,
             palette=color_palette,
             title="Power CMP (" + group_name + " only)",
             xlabel=group_name + " Index",
             legend_label=distance_string
             )
    plt.savefig(path_to_figures + context_string_small + os.sep + group_name + os.sep + "polito_cmp.png",
                dpi=dpi_resolution,
                bbox_inches='tight')

    # Plot the anomaly scores and our considered threshold
    plt.figure(figsize=(7, 7))
    plt.title("Sorted Anomaly Scores (" + group_name + " only)")

    # Calculate an anomaly score
    cmp_group_score = anomaly_score_calc(group_cmp, group)
    # Initialize ana anomaly score empty vector
    cmp_ad_score = np.zeros(len(cmp.distance_matrix)) * np.nan
    # add to the empty array those referring to the group
    cmp_ad_score[group] = cmp_group_score
    # Ordering of all days, from most to least anomalous
    ad_order = np.argsort(cmp_ad_score)[::-1]
    # move na at the end of the vector
    ad_order = np.roll(ad_order, -np.count_nonzero(np.isnan(cmp_ad_score)))
    # save the position of the last available number before NA
    last_value = np.where(cmp_ad_score[ad_order] == min(cmp_ad_score[ad_order]))[0][0]
    # create a vector to plot correctly the graph
    cmp_ad_score_plot = cmp_ad_score[ad_order][0:last_value]

    # set number of aomalies to show as the elbow of the curve
    x_ad = np.array(range(0, len(cmp_ad_score_plot)))
    y_ad = cmp_ad_score_plot
    kn = KneeLocator(x_ad, y_ad, curve='convex', direction='decreasing')
    num_anomalies_to_show = kn.knee

    # limit the number of anomalies
    #if num_anomalies_to_show > 10:
    #    num_anomalies_to_show = 10

    plt.plot(cmp_ad_score_plot)
    plt.ylabel("Anomaly Score")
    plt.axvline(num_anomalies_to_show, ls=":", c="gray")
    anomaly_ticks = list(range(0, len(cmp_ad_score_plot), int(len(cmp_ad_score_plot) / 5)))
    anomaly_ticks.append(num_anomalies_to_show)
    plt.xticks(anomaly_ticks)
    plt.savefig(path_to_figures + context_string_small + os.sep + group_name + os.sep + "polito_anomaly_score.png",
                dpi=dpi_resolution,
                bbox_inches='tight')

    # Visualise the top anomalies according to the CMP
    fig, ax = plt.subplots(num_anomalies_to_show, 2,
                           sharex='all',
                           sharey='all',
                           figsize=(10, 14),
                           gridspec_kw={'wspace': 0., 'hspace': 0.})

    ax[0, 0].set_title("Anomaly vs all")
    ax[0, 1].set_title("Anomaly vs " + group_name)

    for j in range(num_anomalies_to_show):
        anomaly_index = ad_order[j]
        anomaly_range = range(obs_per_day * anomaly_index, obs_per_day * (anomaly_index + 1))
        date = day_labels[anomaly_index]

        line_style = "-"

        ax[j, 0].plot(data.values.reshape((-1, obs_per_day)).T, c="gray", alpha=0.07)
        ax[j, 0].plot(range(context_start * obs_per_hour, (context_end * obs_per_hour + m)),
                      data.values[anomaly_range][context_start * obs_per_hour:(context_end * obs_per_hour + m)],
                      c="red", linestyle=line_style)
        ax[j, 0].plot(data.values[anomaly_range], c="red", linestyle=":")
        ax[j, 0].set_ylim([min_power, max_power])
        ax[j, 0].set_yticks(ticks_power)

        ax[j, 1].plot(data.values.reshape((-1, obs_per_day))[group].T, c="gray", alpha=0.07)
        ax[j, 1].plot(range(context_start * obs_per_hour, (context_end * obs_per_hour + m)),
                      data.values[anomaly_range][context_start * obs_per_hour:(context_end * obs_per_hour + m)],
                      c="red", linestyle=line_style)
        ax[j, 1].plot(data.values[anomaly_range], c="red", linestyle=":")
        ax[j, 0].set_ylim([min_power, max_power])
        ax[j, 0].set_yticks(ticks_power)

        ax[j, 0].text(0, position_y, "CMP-Anomaly " + str(j + 1))
        ax[j, 1].text(0, position_y, date.day_name() + " " + str(date)[:10])

    ax[0, 0].set_xticks(range(0, 97, 24))
    ticklabels = ["{hour}:00".format(hour=(x // obs_per_hour)) for x in range(0, 97, 24)]
    # ticklabels[-1] = ""
    ax[0, 0].set_xticklabels(ticklabels)

    plt.tight_layout()

    ax[num_anomalies_to_show // 2, 0].set_ylabel("Power [kW]")
    ax[num_anomalies_to_show - 1, 1].set_xlabel("Time of day")

    plt.savefig(path_to_figures + context_string_small + os.sep + group_name + os.sep + "polito_anomalies.png",
                dpi=dpi_resolution,
                bbox_inches='tight')
