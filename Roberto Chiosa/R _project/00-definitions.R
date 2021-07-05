
#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

load("./data/df_univariate_full.RData")

#  VARIABLES SETTING ------------------------------------------------------------------

variable <- "Power_total"                                         # this is the timeseries used to perform the MP
w <- 96                                                           # window size # this is the window size used to compute the MP



