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

from distancematrix.calculator import AnytimeCalculator
from distancematrix.generator import ZNormEuclidean
from distancematrix.generator.filter_generator import FilterGenerator
from distancematrix.consumer import MatrixProfileLR
from distancematrix.consumer import ContextualMatrixProfile
from distancematrix.consumer.contextmanager import GeneralStaticManager
from distancematrix.insights import lowest_value_idxs
from distancematrix.insights import highest_value_idxs
from distancematrix.math_tricks import sliding_mean_std
from distancematrix.insights import highest_value_idxs

# Read data for 3 ventilation units, each unit measures CO2 content at 15 minute intervals.
data = [
    pd.read_csv("./Ventilation_Data/ventilation0.csv", index_col=0, header=None, parse_dates=[0], names=["Time", "CO2"]).iloc[:,0],
    pd.read_csv("./Ventilation_Data/ventilation1.csv", index_col=0, header=None, parse_dates=[0], names=["Time", "CO2"]).iloc[:,0],
    pd.read_csv("./Ventilation_Data/ventilation2.csv", index_col=0, header=None, parse_dates=[0], names=["Time", "CO2"]).iloc[:,0]
]
# List of daily dates
data_days = data[0].index[::4*24]

# Boolean arrays indicating whether a day is weekend/weekday
weekdays = np.array([d in range(0,5) for d in data_days.dayofweek])
weekends = np.array([d in range(5,7) for d in data_days.dayofweek])

print("Data[0] goes from ", data[0].index[0], "to", data[0].index[-1])
print("Data[1] goes from ", data[1].index[0], "to", data[1].index[-1])
print("Data[2] goes from ", data[2].index[0], "to", data[2].index[-1])

def znorm(serie):
    return (serie - np.mean(serie)) / np.std(serie)

# Plot some extracts of the data
plot_offset = 4*24*3 # skip 3 days, so the plot starts on a Monday

fig, ax = plt.subplots(3,2,sharex='col', sharey=True, figsize=(15,4), gridspec_kw = {'width_ratios':[2, 2]})
ax[0, 0].plot(data[0])
ax[1, 0].plot(data[1])
ax[2, 0].plot(data[2])

ax[0, 1].plot(data[0].iloc[plot_offset:plot_offset+4*24*14])
ax[1, 1].plot(data[1].iloc[plot_offset:plot_offset+4*24*14])
ax[2, 1].plot(data[2].iloc[plot_offset:plot_offset+4*24*14])

ax[0,1].grid(b=True, axis="x", which='minor', color='gray', linestyle=':')
ax[1,1].grid(b=True, axis="x", which='minor', color='gray', linestyle=':')
ax[2,1].grid(b=True, axis="x", which='minor', color='gray', linestyle=':')
ax[0,1].grid(b=True, axis="x", which='major', color='black', linestyle='-')
ax[1,1].grid(b=True, axis="x", which='major', color='black', linestyle='-')
ax[2,1].grid(b=True, axis="x", which='major', color='black', linestyle='-')

ax[0,0].xaxis.set_major_locator(mdates.MonthLocator())
ax[0,0].xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m"))

ax[0,1].xaxis.set_major_locator(mdates.DayLocator([4, 11, 18]))
ax[0,1].xaxis.set_minor_locator(mdates.DayLocator())
ax[0,1].xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))

ax[1,0].set_ylabel("Measured CO2")

for i in data[0].index[4*9+plot_offset:4*24*14+1+plot_offset:4*24]:
    ax[0,1].text(i, 1200, i.day_name()[:1])

ax[0,0].set_ylim(300,1500)
plt.tight_layout()

# plt.savefig("ventilation.pdf", dpi=300, bbox_inches='tight')

plt.show()

# Setup calculation of Matrix Profile and Contextual Matrix Profile for all datasets.

m = 4*3  # 3 hours

context_morning = GeneralStaticManager(
    [range(x*96 + 24, (x*96)+24+8) for x in range(11616//96)] # daily from 6u-8u
)
context_noon = GeneralStaticManager(
    [range(x*96 + 44, (x*96)+44+8) for x in range(11616//96)] # daily from 11u-13u
)
context_evening = GeneralStaticManager(
    [range(x*96 + 68, (x*96)+68+8) for x in range(11616//96)] # daily from 17u-19u
)

calcs = []
cmps_morning = []
cmps_noon = []
cmps_evening = []
mps = []

for i in range(3):
    calc = AnytimeCalculator(m, data[i].values.T)
    calcs.append(calc)

    calc.add_generator(0, FilterGenerator(ZNormEuclidean()))  # Use ZNormed Euclidean as distance metric

    # Configure 3 CMP calculations
    cmps_morning.append(calc.add_consumer([0], ContextualMatrixProfile(context_morning)))
    cmps_noon.append(calc.add_consumer([0], ContextualMatrixProfile(context_noon)))
    cmps_evening.append(calc.add_consumer([0], ContextualMatrixProfile(context_evening)))

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

# Plot all CMPs
fig, ax = plt.subplots(3,3, figsize=(16,15), sharex=True, sharey=True)
fig.autofmt_xdate()  #The autofmt_xdate() method figure module of matplotlib library is used to rotate them and right align them.

date_labels = mdates.date2num(data_days)
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]

for i in range(3):
    im = ax[i, 0].imshow(cmps_morning[i].distance_matrix, cmap="viridis", vmin=0, vmax=6.8, extent=extents, origin="lower")
    im = ax[i, 1].imshow(cmps_noon[i].distance_matrix, cmap="viridis", vmin=0, vmax=6.8, extent=extents, origin="lower")
    im = ax[i, 2].imshow(cmps_evening[i].distance_matrix, cmap="viridis", vmin=0, vmax=6.8, extent=extents, origin="lower")

fig.subplots_adjust(bottom=0.1, top=0.9, left=0.1, right=0.95,
                    wspace=0.03, hspace=0.03)
cbar_ax = fig.add_axes([0.98, 0.15, 0.02, 0.7])
cbar = fig.colorbar(im, cax=cbar_ax)
cbar.set_label("Distance")

ax[2,2].xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'),)
ax[2,2].yaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
ax[2,2].xaxis.set_major_locator(mticker.MultipleLocator(14))
ax[2,2].yaxis.set_major_locator(mticker.MultipleLocator(14))

ax[0,0].set_title("Ventilation CMP (morning)")
ax[0,1].set_title("Ventilation CMP (noon)")
ax[0,2].set_title("Ventilation CMP (evening)")
plt.show()

# Left: Plot the CMP for weekends only
# Right: Sorted anomaly scores (anomaly score for 1 day is the summed row of the CMP) with anomaly threshold
fig, ax = plt.subplots(1, 2, figsize=(10,5))

ax[0].imshow(nan_diag(cmps_morning[0].distance_matrix[weekends, :][:, weekends]), cmap="viridis", origin="lower")
ax[0].set_title("CMP (weekends only) for unit 1")


summed_dists = nan_diag(cmps_morning[0].distance_matrix[weekends, :][:, weekends])
summed_dists = np.nansum(summed_dists, axis=1)
ax[1].plot(np.sort(summed_dists)[::-1])
ax[1].axvline(6, c="gray")
plt.show()

anomaly_order = np.argsort(summed_dists)[::-1]
print("Top weekend anomalies:")
for i in range(6):
    day = data_days[weekends][anomaly_order[i]]
    print(day.day_name(), str(day)[:10])