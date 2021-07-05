
#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

load("./data/df_univariate_small.RData")

#  VARIABLES SETTING ------------------------------------------------------------------

variable <- "Power_total"                                         # this is the timeseries used to perform the MP
w <- 96                                                           # window size # this is the window size used to compute the MP



x1 = seq(0,2*3.14, 0.05)
x2 = seq(0,1, 0.01)

w <- length(x1)

y_sin1 <- 0.3*sin(x1) + 0.1*runif(length(x))
y_sin2 <- 0.4*sin(x1) + 0.1*runif(length(x))
y_sin3 <- 0.3*sin(x1) + 0.1*runif(length(x))

y_const1 <- 0.03*runif(600)
y_const2 <- 0.03*runif(400)
y_const3 <- 0.03*runif(600)

y_tot <- c(y_const1, y_sin1, y_const2, y_sin2, y_const1, y_sin3, y_const3)

y_tot <- c(y_const1, y_sin1, y_const2, y_const1, y_const1,y_sin1, y_const1, y_const1)

plot(y_tot, type = "l")

mp_univariate <- tsmp(y_tot, window_size = w, exclusion_zone = 0.5 )

plot(mp_univariate)






