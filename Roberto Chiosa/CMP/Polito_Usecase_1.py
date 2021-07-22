# import from default libraries and packages
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.ticker as mticker
import pandas as pd

# import from the local module distancematrix
from distancematrix.calculator import AnytimeCalculator
from distancematrix.generator import ZNormEuclidean, Euclidean
from distancematrix.consumer import MatrixProfileLR, ContextualMatrixProfile
from distancematrix.consumer.contextmanager import GeneralStaticManager

from matplotlib import rc  # font plot
from kneed import KneeLocator  # find knee of curve

path_to_data = 'Polito_Usecase/data/'
path_to_figures = 'Polito_Usecase/figures1/'
color_palette = 'viridis'
dpi_resolution = 300
fontsize = 10
# plt.style.use("seaborn-paper")
rc('font', **{'family': 'serif', 'serif': ['Georgia']})
plt.rcParams.update({'font.size': fontsize})
rc('text', usetex=True)


def CMP_plot(cmp, palette="viridis", title=None, xlabel=None, legendlabel=None, extent=None):
    """
    utils function used to plot the contextual matrix profile

    :param cmp:
    :param extent:
    :param palette:
    :param title:
    :param xlabel:
    :param legendlabel:
    :return:
    """

    if extent is not None:
        # no extent dates given
        plt.imshow(cmp,
                   cmap=palette,
                   origin="lower",
                   extent=extent
                   )
        # Label layout
        plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        plt.gca().yaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        plt.gca().xaxis.set_major_locator(mticker.MultipleLocator(14))
        plt.gca().yaxis.set_major_locator(mticker.MultipleLocator(14))
        plt.gcf().autofmt_xdate()

    else:
        # index as
        plt.imshow(cmp,
                   cmap=palette,
                   origin="lower",
                   vmin=np.min(cmp),
                   vmax=np.max(cmp)
                   )
        plt.xlabel(xlabel)
        ticks = list(range(0, len(cmp), int(len(cmp) / 5)))
        plt.xticks(ticks)
        plt.yticks(ticks)

    cbar = plt.colorbar()

    plt.title(title)
    cbar.set_label(legendlabel)


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

## Add generator
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
CMP_plot(cmp=cmp.distance_matrix,
         palette=color_palette,
         title='Contextual Matrix Profile\n' + distance_string + '\n',
         legendlabel=distance_string,
         extent=extents,
         )


plt.savefig(path_to_figures + "polito_cmp1.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Create boolean arrays to indicate whether each day is a weekday/weekend/saturday/sunday
# - holiday (calendar holidays and academic calendar closures)
# - saturdays (not holidays not working days)
# - workingdays (not holiday and not saturdays)

# load data
annotation_df = pd.read_csv(path_to_data + "polito_holiday.csv", index_col='timestamp', parse_dates=True)

# define arrays
holiday = np.array(annotation_df.T)[0]
saturdays = np.array(annotation_df.T)[1]
workingdays = np.array(annotation_df.T)[2]

# set labels
day_labels = data.index[::obs_per_day]

# Create weekday/weekend only CMP
holiday_cmp = cmp.distance_matrix[:, holiday][holiday, :]
holiday_cmp[holiday_cmp == np.inf] = 0
holiday_dates = data.index[::obs_per_day].values[holiday]

saturday_cmp = cmp.distance_matrix[:, saturdays][saturdays, :]
saturday_cmp[saturday_cmp == np.inf] = 0
saturday_dates = data.index[::obs_per_day].values[saturdays]

workingdays_cmp = cmp.distance_matrix[:, workingdays][workingdays, :]
workingdays_cmp[workingdays_cmp == np.inf] = 0
workingdays_dates = data.index[::obs_per_day].values[workingdays]

# Calculate an anomaly score by summing the values (per type of day) across one axis and averaging
cmp_holiday_score = np.nansum(holiday_cmp, axis=1) / np.count_nonzero(holiday)
# cmp_holiday_score = cmp_holiday_score / np.max(cmp_holiday_score)

cmp_saturday_score = np.nansum(saturday_cmp, axis=1) / np.count_nonzero(saturdays)
# cmp_saturday_score = cmp_saturday_score / np.max(cmp_saturday_score)

cmp_workingdays_score = np.nansum(workingdays_cmp, axis=1) / np.count_nonzero(workingdays)
# cmp_workingdays_score = cmp_holiday_score / np.max(cmp_workingdays_score)

# Merge the scores for all types of day into one array
cmp_ad_score = np.zeros(len(cmp.distance_matrix))

cmp_ad_score[holiday] = cmp_holiday_score
cmp_ad_score[saturdays] = cmp_saturday_score
cmp_ad_score[workingdays] = cmp_workingdays_score

# Ordering of all days, from most to least anomalous
ad_order = np.argsort(cmp_ad_score)[::-1]

# set number of aomalies to show as the elbow of the curve
x_ad = np.array(range(0, len(cmp_ad_score)))
y_ad = cmp_ad_score[ad_order]
kn = KneeLocator(x_ad, y_ad, curve='convex', direction='decreasing')
num_anomalies_to_show = kn.knee

# Plot the anomaly scores and our considered threshold
plt.figure(figsize=(10, 5))
plt.title("Sorted Anomaly Scores")
plt.plot(cmp_ad_score[ad_order])
plt.ylabel("Anomaly Score")
plt.axvline(num_anomalies_to_show, ls=":", c="gray")
anomaly_ticks = list(range(0, len(ad_order), int(len(ad_order) / 5)))
anomaly_ticks.append(num_anomalies_to_show)
plt.xticks(anomaly_ticks)

plt.savefig(path_to_figures + "polito_aggregated_as.png", dpi=dpi_resolution, bbox_inches='tight')

# Plot the CMP together
plt.figure(figsize=(10, 4))

plt.subplot(1, 3, 1)
CMP_plot(cmp=holiday_cmp,
         palette=color_palette,
         title="Power CMP (holiday only)",
         xlabel="Holiday Index",
         legendlabel="Distance")

plt.subplot(1, 3, 2)
CMP_plot(cmp=saturday_cmp,
         palette=color_palette,
         title="Power CMP (Saturday only)",
         xlabel="Saturday Index",
         legendlabel="Distance")

plt.subplot(1, 3, 3)
CMP_plot(cmp=workingdays_cmp,
         palette=color_palette,
         title="Power CMP (Working days  only)",
         xlabel="Working days  Index",
         legendlabel="Distance")

plt.tight_layout()

plt.savefig(path_to_figures + "polito_cmp_detail1.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Visualise the top anomalies according to the CMP
fig, ax = plt.subplots(num_anomalies_to_show, 4, sharex=True, sharey=True, figsize=(10, 14),
                       gridspec_kw={'wspace': 0., 'hspace': 0.})

ax[0, 0].set_title("Anomaly vs all")
ax[0, 1].set_title("Anomaly vs holiday")
ax[0, 2].set_title("Anomaly vs saturdays")
ax[0, 3].set_title("Anomaly vs workingdays")

for i in range(num_anomalies_to_show):
    anomaly_index = ad_order[i]
    anomaly_range = range(obs_per_day * anomaly_index, obs_per_day * (anomaly_index + 1))
    date = day_labels[anomaly_index]

    if holiday[anomaly_index] == True:
        # we are on holiday
        ls1 = "-"
        ls2 = ":"
        ls3 = ":"
        date_col = 1

    if saturdays[anomaly_index] == True:
        # we are on saturdays
        ls1 = ":"
        ls2 = "-"
        ls3 = ":"
        date_col = 2

    if workingdays[anomaly_index] == True:
        # we are on weekdays
        ls1 = ":"
        ls2 = ":"
        ls3 = "-"
        date_col = 3

    ax[i, 0].plot(data.values.reshape((-1, obs_per_day)).T, c="gray", alpha=0.07)
    ax[i, 0].plot(data.values[anomaly_range], c="red")
    ax[i, 0].set_ylim([0, 850])
    ax[i, 0].set_yticks([0, 200, 400, 600, 800])

    ax[i, 1].plot(data.values.reshape((-1, obs_per_day))[holiday].T, c="gray", alpha=0.07)
    ax[i, 1].plot(data.values[anomaly_range], c="red", linestyle=ls1)
    ax[i, 1].set_ylim([0, 850])
    ax[i, 1].set_yticks([0, 200, 400, 600, 800])

    ax[i, 2].plot(data.values.reshape((-1, obs_per_day))[saturdays].T, c="gray", alpha=0.07)
    ax[i, 2].plot(data.values[anomaly_range], c="red", linestyle=ls2)
    ax[i, 2].set_ylim([0, 850])

    ax[i, 3].plot(data.values.reshape((-1, obs_per_day))[workingdays].T, c="gray", alpha=0.07)
    ax[i, 3].plot(data.values[anomaly_range], c="red", linestyle=ls3)
    ax[i, 3].set_ylim([0, 850])
    ax[i, 3].set_yticks([0, 200, 400, 600, 800])

    ax[i, 0].text(0, position_y, "CMP-Anomaly " + str(i + 1))
    ax[i, date_col].text(0, position_y, date.day_name() + " " + str(date)[:10])

ax[0, 0].set_xticks(range(0, 97, 24))
ticklabels = ["{hour}:00".format(hour=(x // obs_per_hour)) for x in range(0, 97, 24)]
ticklabels[-1] = ""
ax[0, 0].set_xticklabels(ticklabels)

plt.tight_layout()

ax[num_anomalies_to_show // 2, 0].set_ylabel("Power [kW]")
ax[num_anomalies_to_show - 1, 1].set_xlabel("Time of day")

plt.savefig(path_to_figures + "polito_cmp_anomalies1.png", dpi=dpi_resolution, bbox_inches='tight')
