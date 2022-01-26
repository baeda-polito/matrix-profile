# HEADER --------------------------------------------
#
# Author: Roberto Chiosa
# Copyright © Roberto Chiosa, 2022
# Email:  roberto.chiosa@polito.it
# 
# Date: 2022-01-26
#
# Script Name: ~/Desktop/matrix-profile/CMP/6 - Plot Calendar Results.R
#
# Script Description:
# 
# This script summarises the results of the anomalyd etection 
# methods using custom calendar plot
#
# Notes:
#
#
#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
source("utils_functions.R")
source("calendarHeat.R")

# load the context decoder dataframe
df_context_decoder <-
  read.csv(file.path("Polito_Usecase", "data", "contexts.csv"))
# list all folders of context
context_folder_vector <-
  list.dirs(file.path("Polito_Usecase", "data"))[-1]

#
# for (context_idx in 1:length(context_folder_vector)) {
#
#   # specific folder of context
#   context_folder <- context_folder_vector[context_idx]
#
#   # decode context string
#   context_string_small <-
#     gsub("Polito_Usecase/data/", "", context_folder)
#
#   context_string <-
#     df_context_decoder$context_string[df_context_decoder$context_string_small == context_string_small]
#
#
#   df <-
#     read.csv(file.path(
#       context_folder,
#       paste0("anomaly_results_Cluster_", context_idx, ".csv")
#     ))


for (context_idx in 1:length(context_folder_vector)) {
  df <- data.frame()
  
  for (cluster_idx in c(1:5)) {
    df_tmp <-
      read.csv(file = file.path(
        context_folder_vector[context_idx],
        paste0("anomaly_results_Cluster_", cluster_idx, ".csv")
      )) %>%
      mutate(Cluster = cluster_idx)
    
    df <- rbind(df, df_tmp)
    
  }
  
  df <- df %>%
    dplyr::arrange(Date) %>%
    dplyr::mutate(severity = cmp_score + energy_score)
  
  dev.new()
  
  png(
    filename = file.path(
      "Polito_Usecase",
      "figures",
      paste0("calendar_result_context_",
        context_idx, ".png")
      
    ),
    res = 200,
    width = 1800,
    height = 700
  )
  
  print({
    extra.calendarHeat(
      dates =  df$Date,
      values = df$severity,
      pvalues = df$Cluster,
      pch.symbol = c(0:5),
      cex.symbol = 1,
      col.symbol='gray30',
      color = 'palette'
    )
  })
  
  dev.off()
  
}
