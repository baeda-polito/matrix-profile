import os
import pandas as pd
from method1 import method1_function
from method2 import method2_function
from method3 import method3_function

# useful paths
path_to_data = os.getcwd() + os.sep + 'data' + os.sep
path_to_figures = os.getcwd() + os.sep + 'figures' + os.sep

#
group = pd.read_csv(path_to_data + "group.csv")
group_cmp = pd.read_csv(path_to_data + "group_cmp.csv")

df = pd.DataFrame()

column1, plot1 = method1_function(group, group_cmp)
column2, plot2 = method2_function(group, group_cmp)
column3, plot3 = method3_function(group, group_cmp)

column1 = []

# append column to df

# majority voting create last column severity

# restituiamo qualcosa


# def anomaly_detection(group_cmp, group):
# applicando funzioni per calcolo anomaly score e majority voting
# trova giorni anomali
