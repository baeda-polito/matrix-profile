import numpy as np
import matplotlib.pyplot as plt

xx=np.linspace(-2, 3, num=100)
yy=np.sin(xx)

fig, ax=plt.subplots()
ax.plot(xx,yy)
plt.show()