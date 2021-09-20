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

# Data can be downloaded at https://github.com/numenta/NAB/tree/master/data/realKnownCause
data = pd.read_csv("nyc_taxi.csv", index_col='timestamp', parse_dates=True)
cluster_df=pd.read_csv("nyc_taxi.csv", index_col='timestamp', parse_dates=True)

# Visualise the data
plt.figure(figsize=(10,3))
plt.subplot(2,1,1)
plt.title("NY Taxi (complete)")
plt.plot(data)
plt.ylabel("Passengers")

plt.subplot(2,1,2)
plt.title("NY Taxi (first two weeks)")
plt.plot(data.iloc[:2*24*7*2])
plt.ylabel("Passengers")

plt.gca().xaxis.set_major_locator(mdates.DayLocator([1, 8, 15]))
plt.gca().xaxis.set_minor_locator(mdates.DayLocator())
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))


plt.grid(b=True, axis="x", which='both', color='black', linestyle=':')

for i in range(14):
    timestamp = data.index[4+i * 48]
    plt.text(timestamp, 25000, timestamp.day_name()[:3])
plt.tight_layout()
plt.show()

# plt.savefig("ny_taxi.pdf", dpi=300, bbox_inches='tight')

# Define configuration for the Contextual Matrix Profile calculation.

m = 44  # 22 hours

# Each context starts between 0 and 2 AM, and lasts 22 hours
contexts = GeneralStaticManager([range(x*48, (x*48)+4) for x in range(len(data)//48)])

calc = AnytimeCalculator(m, data.values.T)

calc.add_generator(0, ZNormEuclidean()) # Znormalized Euclidean Distance

cmp = calc.add_consumer([0], ContextualMatrixProfile(contexts)) # We want to calculate CMP
mp = calc.add_consumer([0], MatrixProfileLR()) # We want to calculate MP


# Calculate Matrix Profile and Contextual Matrix Profile
calc.calculate_columns()

# Create boolean arrays to indicate whether each day is a weekday/weekend/saturday/sunday
weekdays = np.array([d in range(0,5) for d in data.index[::48].dayofweek])
weekends = np.array([d in range(5,7) for d in data.index[::48].dayofweek])
saturdays = np.array([d in range(5,6) for d in data.index[::48].dayofweek])
sundays = np.array([d in range(6,7) for d in data.index[::48].dayofweek])

day_labels = data.index[::48]

print("Dataset contains", len(day_labels), "days")

# Visualise the CMP
# Note the very subtle color difference before and after 2014-08-31

date_labels = mdates.date2num(data.index[::48].values)

plt.figure(figsize=(10,10))
extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(cmp.distance_matrix, extent=extents, cmap="viridis", origin="lower")
cbar = plt.colorbar()
plt.title("Contextual Matrix Profile")

# Label layout
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.gca().yaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.gca().xaxis.set_major_locator(mticker.MultipleLocator(14))
plt.gca().yaxis.set_major_locator(mticker.MultipleLocator(14))
plt.gcf().autofmt_xdate()
cbar.set_label("Distance")
plt.show()

# plt.savefig("ny_taxi_cmp.pdf", dpi=300, bbox_inches='tight')
# Left: Visualise the same CMP, but highlight the subtle change before/after 2014-08-31
# Right: Plot the hourly behavior for all days before/after that date

# Left plot
date_labels = mdates.date2num(data.index[::48].values)

plt.figure(figsize=(12,5))
plt.subplot(1,2,1)

extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
plt.imshow(np.clip(cmp.distance_matrix, 0.4, 1.2), cmap="viridis", extent=extents, origin="lower")
cbar = plt.colorbar()
plt.title("CMP (clipped values)")

# Label layout
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.gca().yaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.gca().xaxis.set_major_locator(mticker.MultipleLocator(28))
plt.gca().yaxis.set_major_locator(mticker.MultipleLocator(28))
plt.gcf().autofmt_xdate()
cbar.set_label("Distance")


# Right plot
plt.subplot(1,2,2)
plt.title("Daily number of passengers")

DAY_TO_SPLIT = 62
split_date = str(data.index[::48][DAY_TO_SPLIT])[:10]
print("Splitting on day", split_date)


# List of colors suitable for the colorblind.
colors = ['#377eb8', '#ff7f00', '#4daf4a',
          '#f781bf', '#a65628', '#984ea3',
          '#999999', '#e41a1c', '#dede00']
c0 = colors[2]
c1 = colors[7]

# Plot before
for i in range(DAY_TO_SPLIT):
    if weekdays[i]:
        plt.plot(data.values[i*48:(i+1)*48], alpha=0.1, c=c0, label="x")

# Plot after
for x in range(DAY_TO_SPLIT,215):
    if weekdays[x]:
        plt.plot(data.values[x*48:(x+1)*48], alpha=0.05, c=c1, label="y")

custom_lines = [Line2D([0], [0], color=c0, lw=1),
                Line2D([0], [0], color=c1, lw=1)]
plt.legend(custom_lines, [f"Before {split_date}", f"After {split_date}"])

plt.xlabel("Time of day")
plt.ylabel("Passengers")
plt.xticks(
    range(0, 49, 8),
    ["{hour}:00".format(hour=(x // 2)) for x in range(0, 49, 8)]
)
plt.show()
# plt.savefig("ny_taxi_laborday.pdf", dpi=300, bbox_inches='tight')