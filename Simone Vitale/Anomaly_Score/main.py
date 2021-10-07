import os
import pandas as pd
from methods import boxplot_fun
from methods import zscore_fun
from methods import elbow_fun
from methods import gesd_fun
import numpy as np

# useful paths
path_to_data = os.getcwd() + os.sep + 'data' + os.sep
path_to_figures = os.getcwd() + os.sep + 'figures' + os.sep

#
group = pd.read_csv(path_to_data + "group.csv",header=None)
group_cmp = pd.read_csv(path_to_data + "group_cmp.csv",header=None)

# new data-frame
try:
 column_1, plot_1= boxplot_fun(group, group_cmp)
except:
    print("Something went wrong in boxplot_fun")
try:
 column_2, plot_2= zscore_fun(group, group_cmp)
except:
    print("Something went wrong in zscore_fun")
try:
 column_3, plot_3= elbow_fun(group, group_cmp)
except:
    print("Something went wrong in elbow_fun")
try:
 column_4, plot_4 = gesd_fun(group, group_cmp)
except:
    print("Something went wrong in gesed_fun")
finally:
    print("The 'try except' is finished")

column_6 = (column_1+column_2+column_3+column_4).astype(int)

df = pd.DataFrame()
df['box-plot']=pd.Series(column_1.astype(int))
df['z-score']=pd.Series(column_2.astype(int))
df['elbow']=pd.Series(column_3)
df['gesd']=pd.Series(column_4)
df['severity']=pd.Series(column_6)



# append column to df

# majority voting create last column severity

# restituiamo qualcosa


# def anomaly_detection(group_cmp, group):
# applicando funzioni per calcolo anomaly score e majority voting
# trova giorni anomali
