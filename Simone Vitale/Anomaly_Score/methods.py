## import
import os
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

'''
## test method
path_to_data = os.getcwd() + os.sep + 'data' + os.sep # get the path
group= pd.read_csv(path_to_data + "group.csv", header=None)
group=np.array(group).flatten()
group_cmp = pd.read_csv(path_to_data+'group_cmp.csv',header=None) # load csv


data=[data[ii].dropna() for ii in range(data[0].size)] #remove nan
data=np.array(data) # from list to array
columns_median=np.median(data, axis=0) # get the median of the columns

fig,ax=plt.subplots(figsize=(6, 6))
bp=ax.boxplot( columns_median,notch=True,patch_artist=True)
ax.set_ylabel('Distribution of the columns median')
ax.axes.get_xaxis().set_visible(False) #remove x-axis
ax.set_title('Notched box plot')
plt.show()

outliers = [flier.get_ydata() for flier in bp["fliers"]] #get the outliers

# create an array of medians according cluster on yearly period
median_of_day=np.zeros(364)
jj=0
for ii in range (365):
    if group[ii]==1 and jj< 74 :
       median_of_day[ii]=columns_median[jj]
       jj=jj+1

#take the outliers
threshold= np.min(outliers)
column_1=(median_of_day>=threshold)*1


## transform into function
'''
######################## METHOD_1_MEDIAN_BOXPLOT ###########################
def method1_function(group,group_cmp):

    import numpy as np
    import matplotlib.pyplot as plt

    group = np.array(group).flatten()

    dim=group_cmp[0].size
    group_cmp = np.array(group_cmp)  # from list to array
    group_cmp = group_cmp[~np.isnan(group_cmp)]# remove nan
    group_cmp=np.reshape(group_cmp, (dim, dim-1))

    columns_median = np.median(group_cmp, axis=0)  # get the median of the columns

    fig, ax = plt.subplots()
    bp = ax.boxplot(columns_median, notch=True, patch_artist=True)
    ax.set_ylabel('Distribution of the columns median')
    ax.axes.get_xaxis().set_visible(False)  # remove x-axis
    ax.set_title('Notched box plot')

    outliers_both_whisker = [flier.get_ydata() for flier in bp["fliers"]]  # get the outliers
    outliers_both_whisker=np.array(outliers_both_whisker)
    outliers= outliers_both_whisker[outliers_both_whisker>np.median(columns_median)]
        # create an array of medians according cluster on yearly period
    median_of_day = np.zeros(group.size-1)
    jj = 0
    for ii in range(group.size):
        if group[ii] == 1 and jj < (len(group_cmp)-1):
            median_of_day[ii] = columns_median[jj]
            jj = jj + 1

    # take the outliers
    threshold = np.min(outliers)
    column_1 = (median_of_day >= threshold) * 1

    return (column_1, fig)


######################## METHOD_2_ZSCORE-MEDIAN ###########################
def method2_function(group,group_cmp):

   import seaborn as sns
   import numpy as np
   import matplotlib.pyplot as plt

   from scipy import stats

   group = np.array(group).flatten()
   dim=group_cmp[0].size
   group_cmp = np.array(group_cmp)  # from list to array
   group_cmp = group_cmp[~np.isnan(group_cmp)]# remove nan
   group_cmp=np.reshape(group_cmp, (dim, dim-1))

   columns_median = np.median(group_cmp, axis=0)  # get the median of the columns
   zscore=stats.zscore(columns_median)

   upper_bound=2

   fig_1 ,ax=plt.subplots()
   sns.kdeplot(data=zscore)
   plt.axvline(x=upper_bound,ymin=0,ymax=1,linestyle='dashed',color='gray')

   # create an array of medians according cluster on yearly period
   outliers = np.zeros(group.size-1)
   jj = 0

   for ii in range(group.size):
       if group[ii] == 1 and jj < (len(group_cmp)-1):
           outliers[ii] = zscore[jj]
           jj = jj + 1

   for kk in range(group.size-1):
       if  outliers[kk]>upper_bound:
           outliers[kk]=1
       else:
           outliers[kk]=0

   # take the outliers
   column_2=outliers

   return(column_2, fig_1)

######################## METHOD_3_ELBOW ###########################
def method3_function(group,group_cmp):

    import numpy as np
    import matplotlib.pyplot as plt
    from kneed import KneeLocator

    group = np.array(group).flatten()

    dim=group_cmp[0].size
    group_cmp = np.array(group_cmp)  # from list to array
    group_cmp = group_cmp[~np.isnan(group_cmp)]# remove nan
    group_cmp=np.reshape(group_cmp, (dim, dim-1))

    columns_median = np.median(group_cmp, axis=0)  # get the median of the columns

    xx = np.array(range(0,columns_median.size))
    yy = np.sort(columns_median)[::-1] #decreasing
    kn = KneeLocator(xx, yy, curve='convex', direction='decreasing')
    num_anomalies_to_show = kn.knee

    fig_2,ax=plt.subplots(figsize=(6,5 ))
    plt.plot(yy)
    plt.ylabel("Anomaly Score")
    plt.title("Sorted Anomaly Scores")
    plt.axvline(num_anomalies_to_show, ls=":", c="gray")
    anomaly_ticks = list(range(0,columns_median.size, int(columns_median.size/ 5)))
    anomaly_ticks.append(num_anomalies_to_show)
    plt.xticks(anomaly_ticks)

    # create an array of medians according cluster on yearly period
    outliers = np.zeros(group.size-1)

    jj = 0
    for ii in range(group.size):
        if group[ii] == 1 and jj < (len(group_cmp)-1):
            outliers[ii] = columns_median[jj]

            jj = jj + 1

    # take the outliers
    anomaly_day = yy[0:num_anomalies_to_show]
    threshold = min(anomaly_day)
    column_3=(outliers >= threshold)*1

    return (column_3, fig_2)

######################## METHOD_4_GESED ###########################
def method4_function(group,group_cmp):

    import matplotlib.pyplot as plt
    import numpy as np
    import scipy.stats as stats
    from GESD_function import ESD_Test

    group = np.array(group).flatten()

    dim=group_cmp[0].size
    group_cmp = np.array(group_cmp)  # from list to array
    group_cmp = group_cmp[~np.isnan(group_cmp)]# remove nan
    group_cmp=np.reshape(group_cmp, (dim, dim-1))

    columns_median = np.median(group_cmp, axis=0)  # get the median of the columns

    fig_3, ax = plt.subplots()
    stats.probplot(columns_median, dist="norm", plot=plt)
    plt.show()

    GESD_df, n_outliers =ESD_Test(columns_median, 0.05, 10)

    # create an array of medians according cluster on yearly period
    outliers = np.zeros(group.size - 1)

    jj = 0
    for ii in range(group.size):
        if group[ii] == 1 and jj < (len(group_cmp) - 1):
            outliers[ii] = columns_median[jj]

            jj = jj + 1

    anomaly_day = np.sort(columns_median)[:-(n_outliers + 1):-1]
    threshold = min(anomaly_day)
    column_4 = (outliers >= threshold) * 1

    return (column_4, fig_3)