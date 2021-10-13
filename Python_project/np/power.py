# import stumpy
import numpy as np
from scipy import signal
import matplotlib.pyplot as plt
from matplotlib import rc
from sklearn.preprocessing import scale
import matplotlib
import copy

from nprofile import NeighborProfile
import utils

#plt.style.use("seaborn-white")
rc('font',**{'family':'serif','serif':['Georgia']})
plt.rcParams.update({'font.size': 15})
#rc('text', usetex=True)

d = 750

power = []
with open('cases/power.txt') as f:
    for line in f:
        power.append(float(line.split('\n')[0]))
power = np.array(power)

print('data length')
print(len(power))


max_sample = 32
scale = 'zscore'

nprofile = NeighborProfile(max_sample=max_sample, scale=scale).fit(power, d).estimate_for_time_series(power)

# the following ugly code are used to find most unsual by excluding overlap subsequences
# anyone can find a better way

the_three = []
the_three.append(np.argmax(nprofile))
number1 = np.argmax(nprofile)

exclusive_begin = 0
if number1 > d:
    exclusive_begin = number1 - d
exclusive_end = number1 + d

nprofile = np.concatenate((nprofile[:exclusive_begin] , nprofile[exclusive_end:]))


number2 = np.argmax(nprofile)
to_append2 = np.argmax(nprofile)
if number2 > the_three[0]:
    to_append2 += d
the_three.append(to_append2)

exclusive_begin = 0
if number2>d:
    exclusive_begin = number2 - d
exclusive_end = number2+d
nprofile = np.concatenate((nprofile[:exclusive_begin] , nprofile[exclusive_end:]))

number3 = np.argmax(nprofile)
to_append3 = np.argmax(nprofile)
if number3 > the_three[0] and number3 > the_three[1]:
    to_append3 += 2*d
elif number3 > the_three[0] or number3 > the_three[1]:
    to_append3 += d

the_three.append(to_append3)


print(the_three)


for idx in the_three:
    plt.plot(power[idx:idx+d])
    plt.show()

# ax2.plot(power_data_dis[idxs[0]:idxs[0]+d], color="k")
# ax3.plot(power_data_dis[idxs[1]:idxs[1]+d], color="r")
# ax4.plot(power_data_dis[idxs[2]:idxs[2]+d], label=r"$s=64$")
# 12000,12288   8352,8544  34368
