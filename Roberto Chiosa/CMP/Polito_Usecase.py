import holidays
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.ticker as mticker
import pandas as pd
import itertools

from distancematrix.calculator import AnytimeCalculator
from distancematrix.generator import ZNormEuclidean, Euclidean
from distancematrix.consumer import MatrixProfileLR, ContextualMatrixProfile
from distancematrix.consumer.contextmanager import GeneralStaticManager
from distancematrix.insights import highest_value_idxs

path_to_data = 'Polito_Usecase/data/'
path_to_figures = 'Polito_Usecase/figures/'

########################################################################################
# load dataset
data = pd.read_csv(path_to_data + "polito.csv", index_col='timestamp', parse_dates=True)

# print dataset main characteristics
print(' POLITO CASE STUDY\n',
      '*********************\n',
      'Electrical Load dataset from Substation C\n',
      '- From\t', data.index[0], '\n',
      '- To\t', data.index[len(data) - 1], '\n',
      '-', len(data), 'observations every 15 min\n',
      '- 96 \t observations per day\n',
      '- 4 \t observations per hour\n'
      )

# useful variables
dpi_resolution = 300
obs_per_day = 96
obs_per_hour = 4
# Visualise the data
plt.figure(figsize=(10, 4))
plt.subplot(2, 1, 1)
plt.title("Total Electrical Load (complete)")
plt.plot(data)
plt.ylabel("Power [kW]")
plt.gca().set_ylim([0,850])
plt.gca().set_yticks ([0,200,400,600,800])

plt.subplot(2, 1, 2)
plt.title("Total Electrical Load (first two weeks)")
plt.plot(data.iloc[:4 * 24 * 7 * 2])
plt.ylabel("Power [kW]")
plt.gca().set_ylim([0,850])
plt.gca().set_yticks ([0,200,400,600,800])

plt.gca().xaxis.set_major_locator(mdates.DayLocator([1, 8, 15]))
plt.gca().xaxis.set_minor_locator(mdates.DayLocator())
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))

plt.grid(b=True, axis="x", which='both', color='black', linestyle=':')

position_x = 6  # position of day labels on x axis
position_y = 750  # position of day labels on y axis

# add day labels on plot
for i in range(14):
    timestamp = data.index[position_x + i * 96]
    plt.text(timestamp, position_y, timestamp.day_name()[:3])

plt.tight_layout()

# save figure to plot directories
plt.savefig(path_to_figures + "polito.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Define configuration for the Contextual Matrix Profile calculation.

# time window length
m = 96 - 4 * 2  # 22 hours

# Each context starts between 0 and 2 AM, and lasts 22 hours
contexts = GeneralStaticManager([range(x * 96, (x * 96) + 4 * 2) for x in range(len(data) // 96)])

calc = AnytimeCalculator(m, data.values.T)

## Add generator as Znormalized Euclidean Distance (original)
# calc.add_generator(0, ZNormEuclidean())

# Add generator as Znormalized Euclidean Distance
calc.add_generator(0, Euclidean())

# We want to calculate CMP initialize element
cmp = calc.add_consumer([0], ContextualMatrixProfile(contexts))

# We want to calculate MP initialize element
mp = calc.add_consumer([0], MatrixProfileLR())

# Calculate Matrix Profile and Contextual Matrix Profile
calc.calculate_columns()

########################################################################################
# Visualise the CMP
# Note the very subtle color difference before and after 2014-08-31
date_labels = mdates.date2num(data.index[::48 * 2].values)

plt.figure(figsize=(10, 10))
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(cmp.distance_matrix, extent=extents, cmap="viridis", origin="lower")
cbar = plt.colorbar()
plt.title("Contextual Matrix Profile\nNot Normalized Euclidean Distance\n")

# Label layout
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.gca().yaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.gca().xaxis.set_major_locator(mticker.MultipleLocator(14))
plt.gca().yaxis.set_major_locator(mticker.MultipleLocator(14))
plt.gcf().autofmt_xdate()
cbar.set_label("Distance")

plt.savefig(path_to_figures + "polito_cmp.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Plot of the Matrix Profile
plt.figure(figsize=(15, 3))
plt.title("Matrix Profile: Not Normalized Euclidean Distance")
plt.plot(data.index[:len(mp.matrix_profile())], mp.matrix_profile())
plt.ylabel("Distance")
plt.show()
plt.savefig(path_to_figures + "polito_mp.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Create boolean arrays to indicate whether each day is a weekday/weekend/saturday/sunday
weekdays = np.array([d in range(0, 5) for d in data.index[::96].dayofweek])
weekends = np.array([d in range(5, 7) for d in data.index[::96].dayofweek])
saturdays = np.array([d in range(5, 6) for d in data.index[::96].dayofweek])
sundays = np.array([d in range(6, 7) for d in data.index[::96].dayofweek])

day_labels = data.index[::96]

holiday = np.array(pd.read_csv(path_to_data + "polito_holiday.csv", index_col='timestamp', parse_dates=True).T)[0]
not_holiday = np.array(1 - holiday, dtype=bool)

# Create weekday/weekend only CMP
weekday_cmp = cmp.distance_matrix[:, weekdays][weekdays, :]
weekday_cmp[weekday_cmp == np.inf] = 0
weekday_dates = data.index[::96].values[weekdays]

weekend_cmp = cmp.distance_matrix[:, weekends][weekends, :]
weekend_cmp[weekend_cmp == np.inf] = 0
weekend_dates = data.index[::96].values[weekends]

saturday_cmp = cmp.distance_matrix[:, saturdays][saturdays, :]
saturday_cmp[saturday_cmp == np.inf] = 0
saturday_dates = data.index[::96].values[saturdays]

sunday_cmp = cmp.distance_matrix[:, sundays][sundays, :]
sunday_cmp[sunday_cmp == np.inf] = 0
sunday_dates = data.index[::96].values[sundays]

# Calculate an anomaly score by summing the values (per type of day) across one axis
cmp_weekday_score = np.nansum(weekday_cmp, axis=1) / np.count_nonzero(weekdays)
cmp_saturday_score = np.nansum(saturday_cmp, axis=1) / np.count_nonzero(saturdays)
cmp_sunday_score = np.nansum(sunday_cmp, axis=1) / np.count_nonzero(sundays)

# Merge the scores for all types of day into one array
cmp_ad_score = np.zeros(len(cmp.distance_matrix))
cmp_ad_score[saturdays] = cmp_saturday_score
cmp_ad_score[sundays] = cmp_sunday_score
cmp_ad_score[weekdays] = cmp_weekday_score

# Ordering of all days, from most to least anomalous
ad_order = np.argsort(cmp_ad_score)[::-1]

# Plot the anomaly scores and our considered threshold
plt.figure(figsize=(15, 3))
plt.title("Sorted Anomaly Scores")
plt.plot(cmp_ad_score[ad_order])
plt.ylabel("Anomaly Score")

plt.axvline(8, ls=":", c="gray")
plt.xticks([0, 10, 20, 50, 100, 150])
plt.show()

# Plot the above figures together

# to get a common scale use the following
max_cmp_val = np.max([
    np.max(weekday_cmp),
    np.max(saturday_cmp),
    np.max(sunday_cmp)
])
min_cmp_val = np.min([
    np.min(weekday_cmp),
    np.min(saturday_cmp),
    np.min(sunday_cmp)
])

plt.figure(figsize=(17, 2.5))
plt.subplot(1, 4, 1)
date_labels = mdates.date2num(weekday_dates)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(weekday_cmp,
           cmap="viridis",
           origin="lower",
           vmin=np.min(weekday_cmp),
           vmax=np.max(weekday_cmp),
           )
cbar = plt.colorbar()
plt.xlabel("Weekday Index")
# plt.yticks([0, 50, 100, 150])
plt.title("Power CMP (weekdays only)")
cbar.set_label("Distance")

plt.subplot(1, 4, 2)
date_labels = mdates.date2num(saturday_dates)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(saturday_cmp,
           cmap="viridis",
           origin="lower",
           vmin=np.min(saturday_cmp),
           vmax=np.max(saturday_cmp),
           )
cbar = plt.colorbar()
plt.xlabel("Saturday Index")
# plt.yticks([0, 10, 20, 30])
plt.title("Power CMP (Saturday only)")
cbar.set_label("Distance")

plt.subplot(1, 4, 3)
date_labels = mdates.date2num(sunday_dates)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(sunday_cmp, cmap="viridis",
           origin="lower",
           vmin=np.min(sunday_cmp),
           vmax=np.max(sunday_cmp),
           )
cbar = plt.colorbar()
plt.xlabel("Sunday Index")
# plt.yticks([0, 10, 20])
plt.title("Power CMP (Sunday only)")
cbar.set_label("Distance")

plt.subplot(1, 4, 4)
plt.title("Sorted Anomaly Scores")
plt.plot(cmp_ad_score[ad_order])
plt.ylabel("Anomaly Score")

plt.axvline(8, ls=":", c="gray")
# plt.xticks([0, 18, 50, 100, 150, 200])

plt.savefig(path_to_figures + "polito_cmp_detail.png", dpi=dpi_resolution, bbox_inches='tight')

########################################################################################
# Sort the anomaly scores for Matrix Profile in a similar way.
# First, gather the indices of the top values of the MP, where each index is
# at least 44 (22 hours) apart from any previous index
mp_ad_order = list(highest_value_idxs(mp.matrix_profile(), m))

plt.figure(figsize=(15, 3))
plt.plot(mp.matrix_profile()[mp_ad_order])

plt.title("Sorted Anomaly Scores (MP)")
plt.ylabel("Anomaly Score")

# plt.axvline(5, ls=":", c="gray")
# plt.axvline(11, ls=":", c="gray")
plt.axvline(16, ls=":", c="gray")
# plt.xticks([0, 16, 50, 100, 150, 200])

# Display the top anomalies according to the MP.
# Again, we output more than the 16 anomalies we consider in the paper.
print("Top anomalies according to MP")

for i, idx in enumerate(itertools.islice(highest_value_idxs(mp.matrix_profile(), 44), 25)):
    date = data.index[idx]
    print(i, date.day_name(), date, "\t", np.round(mp.matrix_profile()[idx], 2))

########################################################################################
# Visualise the top anomalies according to the CMP
num_anomalies_to_show = 8

fig, ax = plt.subplots(num_anomalies_to_show, 3, sharex=True, sharey=True, figsize=(10, 14),
                       gridspec_kw={'wspace': 0., 'hspace': 0.})

ax[0, 0].set_title("Anomaly vs all")
ax[0, 1].set_title("Anomaly vs weekday")
ax[0, 2].set_title("Anomaly vs weekend")

for i in range(num_anomalies_to_show):
    anomaly_index = ad_order[i]
    anomaly_range = range(96 * anomaly_index, 96 * (anomaly_index + 1))
    date = day_labels[anomaly_index]

    if date.dayofweek in (5, 6):
        ls1 = ":"
        ls2 = "-"
        date_col = 2
    else:
        ls1 = "-"
        ls2 = ":"
        date_col = 1

    ax[i, 0].plot(data.values.reshape((-1, 96)).T, c="gray", alpha=0.07)
    ax[i, 0].plot(data.values[anomaly_range], c="red")

    ax[i, 1].plot(data.values.reshape((-1, 96))[weekdays].T, c="gray", alpha=0.07)
    ax[i, 1].plot(data.values[anomaly_range], c="red", linestyle=ls1)

    ax[i, 2].plot(data.values.reshape((-1, 96))[weekends].T, c="gray", alpha=0.07)
    ax[i, 2].plot(data.values[anomaly_range], c="red", linestyle=ls2)

    ax[i, 0].text(0, 650, "CMP-Anomaly " + str(i + 1))
    ax[i, date_col].text(0, 650, date.day_name() + " " + str(date)[:10])

ax[0, 0].set_xticks(range(0, 97, 24))
ticklabels = ["{hour}:00".format(hour=(x // 4)) for x in range(0, 97, 24)]
ticklabels[-1] = ""
ax[0, 0].set_xticklabels(ticklabels)

# plt.tight_layout()

ax[num_anomalies_to_show // 2, 0].set_ylabel("Power [kW]")
ax[num_anomalies_to_show - 1, 1].set_xlabel("Time of day")

plt.savefig(path_to_figures + "polito_cmp_anomalies.png", dpi=dpi_resolution, bbox_inches='tight')

# Visualise the top anomalies according to the MP
num_anomalies_to_show = 8

fig, ax = plt.subplots(num_anomalies_to_show, 3, sharex=True, sharey=True, figsize=(10, 14),
                       gridspec_kw={'wspace': 0., 'hspace': 0.})
ax[0, 0].set_title("Anomaly vs all")
ax[0, 1].set_title("Anomaly vs weekday")
ax[0, 2].set_title("Anomaly vs weekend")

mp_cached = mp.matrix_profile()
for i, anomaly_index in enumerate(itertools.islice(highest_value_idxs(mp_cached, m), num_anomalies_to_show)):
    # Anomalies can be split over 2 days here
    day_index = anomaly_index // 96
    day_shift = anomaly_index % 96
    anomaly_range_x1 = range(0, day_shift)
    anomaly_range_y1 = range(day_index * 96, day_index * 96 + day_shift)
    anomaly_range_x2 = range(day_shift, min(day_shift + m, 96))
    anomaly_range_y2 = range(day_index * 96 + day_shift, day_index * 96 + day_shift + len(anomaly_range_x2))
    anomaly_range_x3 = range(0, day_shift - (96 - m))
    anomaly_range_y3 = range(day_index * 96 + day_shift + len(anomaly_range_x2),
                             (day_index + 1) * 96 + anomaly_range_x3.stop - anomaly_range_x3.start)
    anomaly_range_x4 = range(day_shift - (96 - m), 96)
    anomaly_range_y4 = range((day_index + 1) * 96 + len(anomaly_range_x3), (day_index + 2) * 96)

    date1 = data.index[anomaly_index]
    date2 = data.index[anomaly_index + 96]

    if date1.dayofweek in (5, 6):
        ls1, ls3 = (":", "-")
        date_col = 2
    else:
        ls1, ls3 = ("-", ":")
        date_col = 1
    if date2.dayofweek in (5, 6):
        ls2, ls4 = (":", "-")
    else:
        ls2, ls4 = ("-", ":")

    ax[i, 0].plot(data.values.reshape((-1, 96)).T, c="gray", alpha=0.05)
    ax[i, 0].plot(anomaly_range_x2, data.values[anomaly_range_y2], c="red")
    ax[i, 0].plot(anomaly_range_x3, data.values[anomaly_range_y3], c="red")

    ax[i, 1].plot(data.values.reshape((-1, 96))[weekdays].T, c="gray", alpha=0.05)
    ax[i, 1].plot(anomaly_range_x2, data.values[anomaly_range_y2], c="red", linestyle=ls1)
    ax[i, 1].plot(anomaly_range_x3, data.values[anomaly_range_y3], c="red", linestyle=ls2)

    ax[i, 2].plot(data.values.reshape((-1, 96))[weekends].T, c="gray", alpha=0.05)
    ax[i, 2].plot(anomaly_range_x2, data.values[anomaly_range_y2], c="red", linestyle=ls3)
    ax[i, 2].plot(anomaly_range_x3, data.values[anomaly_range_y3], c="red", linestyle=ls4)

    ax[i, 0].text(0, 650, "MP-Anomaly " + str(i + 1))
    ax[i, date_col].text(0, 650, date1.day_name() + " " + str(date1)[:16])

ax[0, 0].set_xticks(range(0, 97, 24))
ticklabels = ["{hour}:00".format(hour=(x // 4)) for x in range(0, 97, 24)]
ticklabels[-1] = ""
ax[0, 0].set_xticklabels(ticklabels)

# plt.tight_layout()

ax[num_anomalies_to_show // 2, 0].set_ylabel("Power[kW]")
ax[num_anomalies_to_show - 1, 1].set_xlabel("Time of day")

plt.savefig(path_to_figures + "polito_mp_anomalies.png", dpi=dpi_resolution, bbox_inches='tight')
