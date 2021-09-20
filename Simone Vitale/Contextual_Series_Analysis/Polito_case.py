import random
import collections
import os
import math
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.ticker as mticker
from matplotlib.lines import Line2D
import matplotlib.gridspec as grd
import pandas as pd
import time
import itertools
import stumpy

from distancematrix.calculator import AnytimeCalculator
from distancematrix.generator.euclidean import Euclidean
from distancematrix.generator.filter_generator import FilterGenerator
from distancematrix.consumer import MatrixProfileLR
from distancematrix.consumer import ContextualMatrixProfile
from distancematrix.consumer.contextmanager import GeneralStaticManager
from distancematrix.insights import lowest_value_idxs
from distancematrix.insights import highest_value_idxs
from distancematrix.math_tricks import sliding_mean_std
from distancematrix.insights import highest_value_idxs
from kneed import KneeLocator

plt.close('all') #close all plots
os.system('clear')

# Set the font dictionaries (for plot title and axis titles)
title_font = {'fontname':'Arial', 'size':'20', 'color':'black', 'weight':'normal'}
axis_font = {'fontname':'Arial', 'size':'10'}


# Read data of total cunsumption Power [kW]

path_data='/Users/simonevitale/Desktop/matrix-profile/Simone Deho/'
data = pd.read_csv(path_data + "df_cabinaC_2019_labeled.csv",usecols=['Date_Time','Total_Power'], index_col='Date_Time', parse_dates= True)
cluster_df=pd.read_csv("/Users/simonevitale/Desktop/matrix-profile/Roberto Chiosa/CMP/Polito_Usecase/data/polito_holiday.csv", index_col='timestamp', parse_dates=True)

#data= data.drop(data.index[18000:35040],0,inplace=False)

# List of daily dates
data_days = data.index[::4*24]  #The index (row labels) of the DataFrame.

# Boolean arrays indicating whether a day is weekend/weekday
weekdays = np.array([d in range(0,5) for d in data_days.dayofweek])
weekends = np.array([d in range(5,7) for d in data_days.dayofweek])
saturdays = np.array([d in range(5,6) for d in data_days.dayofweek])
sundays = np.array([d in range(6,7) for d in data_days.dayofweek])

print("\n Data goes from ", data.index[0], "to", data.index[-1])
offset = 9984

# plot figure
fig, ax = plt.subplots(2,1,sharey=True, figsize=(15,4))

ax[0].plot(data)
ax[1].plot(data.iloc[offset:offset+(4*24*28)])

ax[0].grid(b=True, axis="x", which='minor', color='gray', linestyle=':')
ax[1].grid(b=True, axis="x", which='minor', color='gray', linestyle=':')
ax[0].grid(b=True, axis="x", which='major', color='black', linestyle='-')
ax[1].grid(b=True, axis="x", which='major', color='black', linestyle='-')

ax[0].xaxis.set_major_locator(mdates.MonthLocator())
ax[0].xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m"))

ax[1].xaxis.set_major_locator(mdates.DayLocator([15, 22, 29, 6, 13]))
ax[1].xaxis.set_minor_locator(mdates.DayLocator())
ax[1].xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))

ax[0].set_ylabel("Power by months [kW]")
ax[1].set_ylabel("Power by weeks [kW]")

plt.show()

# Setup calculation of Matrix Profile and Contextual Matrix Profile for all datasets.

m = 4*4 # 4 hours

context_1= GeneralStaticManager(
    [range(x*96, x*96+8) for x in range(data_days.size)] # daily from 0:00u-2:00u
)

calcs = []
cmp_1 = []
mps = []


calc = AnytimeCalculator(m, data.values.T)
calcs.append(calc)
calc.add_generator(0, FilterGenerator(Euclidean()))  # Use Euclidean as distance metric

# Configure CMP calculations
cmp_1.append(calc.add_consumer([0], ContextualMatrixProfile(context_1)))

# Configure MP calculation
mps.append(calc.add_consumer([0], MatrixProfileLR()))

# Calculate for all datasets.
for calc in calcs:
    calc.calculate_columns(print_progress=True)

def nan_diag(matrix):
    """
    Fills the diagonal of the passed square matrix with nans.
    """

    h, w = matrix.shape

    if h != w:
        raise RuntimeError("Matrix is not square")

    matrix = matrix.copy()
    matrix[range(h), range(w)] = np.nan
    return matrix

# Plot CMP
fig_1, ax = plt.subplots(figsize=(10,10))
fig_1.autofmt_xdate()  #The autofmt_xdate() method figure module of matplotlib library is used to rotate them and right align them.
plt.rc('font',size=14)
date_labels = mdates.date2num(data_days)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]

im = ax.imshow(cmp_1[0].distance_matrix, cmap="viridis", extent=extents, origin="lower")
cbar = fig_1.colorbar(im)
cbar.set_label("Distance", loc='top')

ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
ax.yaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
ax.xaxis.set_major_locator(mticker.MultipleLocator(28))
ax.yaxis.set_major_locator(mticker.MultipleLocator(28))

ax.set_title("Power_consumption CMP_1",**title_font)
for label in (ax.get_xticklabels() + ax.get_yticklabels()):
    label.set_fontname('Arial')
    label.set_fontsize(14)

plt.show()


# create MP with two different libraries
mp_1 = stumpy.stump(data['Total_Power'], m, normalize=False)

def matrix_profile(matrix_profile_left,matrix_profile_right):
    """
    Creates the matrix profile based on the left and right matrix profile.

    :return: 1D array
    """
    left_best =matrix_profile_left < matrix_profile_right
    return np.where(
        left_best,
        matrix_profile_left,
        matrix_profile_right
    )
mp=matrix_profile(mps[0].matrix_profile_left,mps[0].matrix_profile_right)

#Plot MP
xx = np.arange(0, mp.size, 1)
fig_2, axs = plt.subplots(2, 1,figsize=(14,6))
plt.rc('font',size=10)
plt.xticks(np.arange(0,mp.size,2000))

axs[0].plot(xx,mp)
axs[0].set_title('MP_LR')

axs[1].plot(mp_1[:,0] ,color='tab:orange')
axs[1].set_title('MP_STUMPY')
for tick in axs[1].get_xticklabels():
            tick.set_rotation(45)

plt.show()

# Create weekday/weekend only CMP
weekday_cmp = cmp_1[0].distance_matrix[:, weekdays][weekdays, :]
weekday_cmp[weekday_cmp == np.inf] = 0
weekday_dates = data_days.values[weekdays]

weekend_cmp = cmp_1[0].distance_matrix[:, weekends][weekends, :]
weekend_cmp[weekend_cmp == np.inf] = 0
weekend_dates = data_days.values[weekends]

saturday_cmp = cmp_1[0].distance_matrix[:, saturdays][saturdays, :]
saturday_cmp[saturday_cmp == np.inf] = 0
saturday_dates = data_days.values[saturdays]

sunday_cmp = cmp_1[0].distance_matrix[:, sundays][sundays, :]
sunday_cmp[sunday_cmp == np.inf] = 0
sunday_dates = data_days.values[sundays]

# Visualisation of weekday only CMP
date_labels = mdates.date2num(weekday_dates)
fig_3, ax = plt.subplots(figsize=(5,5))
plt.rc('font',size=10)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
im=plt.imshow(weekday_cmp, cmap="viridis",
           origin="lower")
cbar = plt.colorbar(im)
plt.title("Contextual Matrix Profile (weekdays only)")
for label in (ax.get_xticklabels() + ax.get_yticklabels()):
    label.set_fontname('Arial')
    label.set_fontsize(14)
plt.show()

# Visualisation of weekend only CMP
date_labels = mdates.date2num(weekend_dates)
fig_4, ax = plt.subplots(figsize=(5,5))
plt.rc('font',size=10)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(weekend_cmp, cmap="viridis",
           origin="lower")
cbar = plt.colorbar()
plt.title("Contextual Matrix Profile (weekends only)")
for label in (ax.get_xticklabels() + ax.get_yticklabels()):
    label.set_fontname('Arial')
    label.set_fontsize(14)
plt.show()

# Visualisation of CMP for Saturday and Sunday separately
plt.figure(figsize=(10,5))
plt.subplot(1, 2, 1)

date_labels = mdates.date2num(saturday_dates)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(saturday_cmp, cmap="viridis",
           origin="lower")
cbar = plt.colorbar()
plt.title("CMP (Saturdays only)")

plt.subplot(1, 2, 2)

date_labels = mdates.date2num(sunday_dates)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(sunday_cmp, cmap="viridis",
           origin="lower",
          vmin=0)
cbar = plt.colorbar()
plt.title("CMP (Sundays only)")
plt.show()

# Calculate an anomaly score by summing the values (per type of day) across one axis
cmp_weekday_score = np.nansum(weekday_cmp, axis=1) / np.count_nonzero(weekdays)
cmp_saturday_score = np.nansum(saturday_cmp, axis=1) / np.count_nonzero(saturdays)
cmp_sunday_score = np.nansum(sunday_cmp, axis=1) / np.count_nonzero(sundays)

# Merge the scores for all types of day into one array
cmp_ad_score = np.zeros(len(cmp_1[0].distance_matrix))
cmp_ad_score[saturdays] = cmp_saturday_score
cmp_ad_score[sundays] = cmp_sunday_score
cmp_ad_score[weekdays] = cmp_weekday_score

# Ordering of all days, from most to least anomalous
ad_order = np.argsort(cmp_ad_score)[::-1]

# Plot the anomaly scores and our considered threshold
plt.figure(figsize=(15,3))
kneedle = KneeLocator(
 range(ad_order.size),cmp_ad_score[ad_order], S=2, curve="convex", direction="decreasing", interp_method="interp1d")
kneedle.plot_knee()
plt.ylabel("Anomaly Score")
plt.title("Sorted Anomaly Scores")
plt.xticks([0, 31, 50, 100, 150, 200, 250, 300, 350])
plt.show()

# Display the top anomalies according to the CMP.
# In the paper we take the top 18 anomalies, but output more here out of interest
print("Top anomalies according to CMP")

for i in range(30):
    anomaly_index = ad_order[i]
    date = data_days[anomaly_index]
    print(i, date.day_name(), str(date)[:10], "\t", np.round(cmp_ad_score[anomaly_index], 2))

# Visualise the top anomalies according to the CMP
num_anomalies_to_show = 8

fig_3, ax = plt.subplots(num_anomalies_to_show, 3, sharex=True, sharey=True, figsize=(10, 14),
                       gridspec_kw={'wspace': 0., 'hspace': 0.})

ax[0, 0].set_title("Anomaly vs all")
ax[0, 1].set_title("Anomaly vs weekday")
ax[0, 2].set_title("Anomaly vs weekend")

for i in range(num_anomalies_to_show):

    anomaly_index = ad_order[i]
    anomaly_range = range(96 * anomaly_index, 96 * (anomaly_index + 1))
    date = data_days[anomaly_index]

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

    ax[i, 0].text(0, 700, "CMP-Anomaly " + str(i + 1))
    ax[i, date_col].text(0, 700, date.day_name() + " " + str(date)[:10])

ax[0, 0].set_xticks(range(0, 97, 24))
ticklabels = ["{hour}:00".format(hour=(x // 2)) for x in range(0, 49, 12)]
ticklabels[-1] = ""
ax[0, 0].set_xticklabels(ticklabels)

# plt.tight_layout()

ax[num_anomalies_to_show // 2, 0].set_ylabel("Passengers")
ax[num_anomalies_to_show - 1, 1].set_xlabel("Time of day")

# plt.savefig("ny_taxi_cmp_anomalies.pdf", dpi=300, bbox_inches='tight')
plt.show()