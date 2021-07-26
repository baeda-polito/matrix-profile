#Finding and Visualizing Time Series Motifs of All Lengths using the Matrix Profile
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import cm
import ipywidgets as widgets
from ipywidgets import interact, Layout
import stumpy

# import data frame
df = pd.read_csv("./data/df_two_months.csv")
df = df.rename(columns = {'Power_total': 'P_t', 'Power_mechanical_room': 'P_m_r', 'Power_dimat': 'P_d'}, inplace = False)

m_250 = 250
m_500 = 500
mp_250 = stumpy.stump(df["P_t"], m=m_250)
mp_500 = stumpy.stump(df["P_t"], m=m_500)
motif_idx_250 = np.argmin(mp_250[:, 0])
motif_idx_500 = np.argmin(mp_500[:, 0])
nn_idx_250 = mp_250[motif_idx_250, 1]
nn_idx_500 = mp_500[motif_idx_500, 1]

min_m, max_m = 100, 3000
df_PMP = stumpy.stimp(df['P_t'], min_m=min_m, max_m=max_m, percentage=0.01)  # This percentage controls the extent of `stumpy.scrump` completion
percent_m = 0.01  # The percentage of windows to compute
n = np.ceil((max_m - min_m) * percent_m).astype(int)
for _ in range(2*n):
    df_PMP.update()

fig = plt.figure()
fig.canvas.toolbar_visible = False
fig.canvas.header_visible = False
fig.canvas.footer_visible = False

lines = [motif_idx_250, motif_idx_500, nn_idx_250, nn_idx_500]
color_map = cm.get_cmap("Greys_r", 256)
im = plt.imshow(df_PMP.PAN_, cmap=color_map, origin="lower", interpolation="none", aspect="auto")
plt.xlabel("Time", fontsize="20")
plt.ylabel("m", fontsize="20")
plt.clim(0.0, 1.0)
plt.colorbar()
plt.tight_layout()

# Draw some vertical lines where each motif and nearest neighbor are located
if lines is not None:
    for line in lines:
        plt.axvline(x=line, color='red')

plt.show()
