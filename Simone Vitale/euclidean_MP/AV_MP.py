import numpy as np
from scipy.io import loadmat
import pandas as pd
import matplotlib.pyplot as plt
from stumpy import stump
#from stumpy import mass


df_power = pd.read_csv("./data/df_two_months.csv")
#to_del=np.arange(2000,5855,1)
#df_power.drop(df_power.index[to_del],inplace=True)

m=24

#AV_complexity
complexity_vector = np.zeros(len(df_power['Power_total']) - m + 1)

for i in range(len(df_power['Power_total']) - m + 1):
    CE = np.diff(df_power['Power_total'][i:i + m])
    CE = np.power(CE, 2)
    CE = np.sum(CE)
    CE = np.sqrt(CE)
    complexity_vector[i] = CE

annotation_vector = complexity_vector
annotation_vector = annotation_vector - np.amin(annotation_vector)
annotation_vector = annotation_vector / np.amax(annotation_vector)

fig, axis = plt.subplots(3, sharex=True)
plt.suptitle('P_t Complexity Vector', fontsize='15')

axis[0].plot(df_power['Power_total'], color='mediumspringgreen', label='P_t')
axis[0].set_title('P_t')

axis[1].plot(complexity_vector, color='seagreen', label='Matrix Profile')
axis[1].set_ylabel('Complexity')
axis[1].set_title('Complexity Vector')

axis[2].plot(annotation_vector, color='slateblue', label='Annotation Vector')
axis[2].set_xlabel('Time')
axis[2].set_title('Annotation Vector')

plt.show()

matrix_profile = stump(df_power['Power_total'], m, normalize=False)

def get_corrected_matrix_profile(matrix_profile, annotation_vector):
    corrected_matrix_profile = matrix_profile[:, 0] + ((1 - annotation_vector) * np.max(matrix_profile[:, 0]))
    corrected_matrix_profile = np.column_stack((corrected_matrix_profile, matrix_profile[:, [1, 2, 3]]))

    return corrected_matrix_profile

corrected_matrix_profile = get_corrected_matrix_profile(matrix_profile, annotation_vector)


fig, axis = plt.subplots(2, sharex=True)
plt.suptitle('Matrix Profile Correction Using Annotation Vector', fontsize='15')

axis[0].plot(matrix_profile[:, 0], color='darkorange', linewidth=1, alpha=0.3, label='Matrix Profile')
axis[0].plot(corrected_matrix_profile[:, 0], color='mediumvioletred', label='Corrected Matrix Profile')
axis[0].set_ylabel('Euclidean Distance')
axis[0].set_title('Corrected & Original Matrix Profile')
axis[0].legend(loc ='upper left')

axis[1].plot(annotation_vector, color='slateblue', label='Annotation Vector')
axis[1].set_xlabel('Time')
axis[1].set_title('Annotation Vector')

plt.show()


def get_discord_data(data, matrix_profile, m):
    discord_index = np.argmax(matrix_profile[:, 0])
    discord_x = np.arange(discord_index, discord_index + m)
    motif_y = data[discord_index:discord_index + m]
    motif = (discord_index, discord_x, motif_y)

    neighbor_index = matrix_profile[discord_index, 1]
    neighbor_x = np.arange(neighbor_index, neighbor_index + m)
    neighbor_y = data[neighbor_index:neighbor_index + m]
    neighbor = (neighbor_index, neighbor_x, neighbor_y)

    return motif, neighbor


motif, neighbor = get_discord_data(df_power['Power_total'], corrected_matrix_profile, m)

fig, axis = plt.subplots(2, sharex=True)
plt.suptitle('Discord Discovery With Matrix Profile', fontsize='15')

axis[0].plot(df_power['Power_total'], color='darkgoldenrod', label='P_t')
axis[0].plot(motif[1], motif[2], color='red', linewidth=6, alpha=0.5, label='Motif')
axis[0].plot(neighbor[1], neighbor[2], color='mediumblue', linewidth=6, alpha=0.5, label='Nearest Neighbour')
axis[0].legend()
axis[0].axvline(x=motif[0], color='grey', alpha=0.5, linestyle='--')
axis[0].axvline(x=neighbor[0], color='grey', alpha=0.5, linestyle='--')
axis[0].set_title('P_t')

axis[1].plot(corrected_matrix_profile[:, 0], color='darkorange', label='Matrix Profile')
axis[1].axvline(x=motif[0], color='grey', alpha=0.5, linestyle='--')
axis[1].axvline(x=neighbor[0], color='grey', alpha=0.5, linestyle='--')
axis[1].set_xlabel('Time')
axis[1].set_ylabel('Euclidean Distance')
axis[1].set_title('Matrix Profile')

plt.show()
