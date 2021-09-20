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
import sys

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

# Read data of total cunsumption Power [kW] and cluster

path_data='/Users/simonevitale/Desktop/matrix-profile/Simone Deho/'
path_data_cluster='/Users/simonevitale/Desktop/matrix-profile/Roberto Chiosa/CMP/Polito_Usecase/data/'
data = pd.read_csv(path_data + "df_cabinaC_2019_labeled.csv",usecols=['Date_Time','Total_Power'], index_col='Date_Time', parse_dates= True)
cluster_df=pd.read_csv(path_data_cluster+'polito_holiday.csv', index_col='timestamp', parse_dates=True)

# List of daily dates
data_days = data.index[::4*24]  #The index (row labels) of the DataFrame.

# Boolean arrays indicating whether a day belong to cluster
cluster_1=cluster_df['Cluster_1']

print("\n Data goes from ", data.index[0], "to", data.index[-1])

# Setup calculation of Matrix Profile and Contextual Matrix Profile for all datasets.
m = 4*4 # 4 hours

context_1= GeneralStaticManager(
    [range(x*96, x*96+8) for x in range(data_days.size)]) # daily from 0:00u-2:00u

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

matrix=[]

# Saving the reference of the standard output
original_stdout = sys.stdout
with open('cntxt_1_mean_of_distances.txt', 'w') as f: #print on a file
 sys.stdout = f

 for ii in range(1,7):
  # Create cluster_i only CMP
  cluster= cluster_df['Cluster_'+str(ii)]
  cluster_cmp = cmp_1[0].distance_matrix[:, cluster][cluster, :]
  cluster_cmp=nan_diag(cluster_cmp)
  cluster_dates = data_days.values[cluster]
  matrix.append(nan_diag(cluster_cmp))

  # Visualisation of weekday only CMP
  date_labels = mdates.date2num(cluster_dates)

  fig, ax = plt.subplots(figsize=(7,5))
  #extents = [date_labels[0], date_labels[-1], date_labels[0], date_labels[-1]]
  im=plt.imshow(matrix[ii-1], cmap="viridis", vmin=np.nanmin(matrix[ii-1])//1-1, vmax=np.nanmax(matrix[ii-1])//1+1,
             origin="lower")
  plt.title("CMP_cntxt_1_cluster_%d" %ii, **title_font,loc='left')
  cbar_ax = fig.add_axes([0.88, 0.15, 0.04, 0.7])
  fig.colorbar(im, cax=cbar_ax)

  for label in (ax.get_xticklabels() + ax.get_yticklabels()):
      label.set_fontname('Arial')
      label.set_fontsize(14)
  plt.show()

  # Calculate an anomaly score
  cmp_cluster_score = np.nansum(cluster_cmp, axis=1) / np.count_nonzero(cluster)
  # Merge the scores for all types of day into one array
  cmp_ad_score = np.zeros(len(cmp_1[0].distance_matrix))*np.nan
  cmp_ad_score[cluster] = cmp_cluster_score
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

  # Plot the anomaly scores and our considered threshold
  plt.figure(figsize=(15, 3))
  plt.plot(cmp_ad_score_plot)
  plt.ylabel("Anomaly Score")
  plt.title("Sorted Anomaly Scores")
  plt.axvline(num_anomalies_to_show, ls=":", c="gray")
  anomaly_ticks = list(range(0, len(cmp_ad_score_plot), int(len(cmp_ad_score_plot) / 5)))
  anomaly_ticks.append(num_anomalies_to_show)
  plt.xticks(anomaly_ticks)
  plt.show()

  print("Top anomalies according to CMP_cluster_%d" %ii)

  for kk in range(num_anomalies_to_show):
     anomaly_index = ad_order[kk]
     date = data_days[anomaly_index]
     print(kk, date.day_name(), str(date)[:10], "\t", np.round(cmp_ad_score[anomaly_index], 2))

  print('\n\n\n\n')

  # Visualise the top anomalies according to the CMP

  fig_1, ax = plt.subplots(num_anomalies_to_show, 2, sharex=True, sharey=True, figsize=(10, 14),
                           gridspec_kw={'wspace': 0., 'hspace': 0.})

  ax[0, 0].set_title("Anomaly vs all")
  ax[0, 1].set_title("Anomaly vs cluster_"+str(ii))

  for jj in range(num_anomalies_to_show):

      anomaly_index = ad_order[jj]
      anomaly_range = range(96 * anomaly_index, 96 * (anomaly_index + 1))
      date = data_days[anomaly_index]

      ax[jj, 0].plot(data.values.reshape((-1, 96)).T, c="gray", alpha=0.07)
      ax[jj, 0].plot(range(8),data.values[anomaly_range][:8], c="red",linestyle=':')
      ax[jj, 0].plot(range(9,96),data.values[anomaly_range][9:96], c="red",linestyle='-')

      ax[jj, 1].plot(data.values.reshape((-1, 96))[cluster].T, c="gray", alpha=0.07)
      ax[jj, 1].plot(data.values[anomaly_range], c="red", linestyle=':')

      ax[jj, 0].text(0, 700, "CMP-Anomaly " + str(jj + 1))
      ax[jj, 1].text(0, 700, date.day_name() + " " + str(date)[:10])

  ax[0, 0].set_xticks(range(0, 97, 24))
  ticklabels = ["{hour}:00".format(hour=(x // 2)) for x in range(0, 49, 12)]
  ticklabels[-1] = ""
  ax[0, 0].set_xticklabels(ticklabels)

  # plt.tight_layout()

  ax[num_anomalies_to_show // 2, 0].set_ylabel("Power[kW]")
  ax[num_anomalies_to_show - 1, 0].set_xlabel("Time of day")

  # plt.savefig("ny_taxi_cmp_anomalies.pdf", dpi=300, bbox_inches='tight')
  plt.show()
f.close()