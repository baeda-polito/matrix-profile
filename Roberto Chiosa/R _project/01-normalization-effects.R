
#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

load("./data/df_univariate_full.RData")

#  VARIABLES SETTING ------------------------------------------------------------------

variable <- "Power_total"                                         # this is the timeseries used to perform the MP
w <- 96                                                           # window size # this is the window size used to compute the MP


# figure_directory <- gsub(" ", "", paste("MP-",variable,"-w",w ))  # this is the figure directory of this analysis
# figure_path <- gsub(" ", "", paste("./figures/01-preliminary-analysis/", figure_directory)) # path to figure  directory
# 
# if ( file.exists(figure_path) == FALSE ){ # directory does not exists
#   dir.create( figure_path )
# }
# 
# # get current script path
# A <- rstudioapi::getSourceEditorContext()$path
# 
# # get current working directory
# B <- getwd()
# 
# gsub(B, "", A)


plot(df_univariate$Power_total, type = "l")
