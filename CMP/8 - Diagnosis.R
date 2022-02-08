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
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("global_vars.R")     # Loads global variables
source("utils_functions.R") # Loads utils functions
source("calendarHeat.R")    # Loads the custom defined calendar heatmap


# load the context decoder dataframe
df_context_decoder <-
  read.csv(file.path("Polito_Usecase", "data", "contexts.csv"))
# list all folders of context
context_folder_vector <-
  list.dirs(file.path("Polito_Usecase", "data"))[-1]

df_diagnosis <- data.frame()
for (context_idx in 1:length(context_folder_vector)) {
  df <- data.frame()
  
  for (cluster_idx in c(1:5)) {
    df_tmp <-
      read.csv(file = file.path(
        context_folder_vector[context_idx],
        paste0("anomaly_results_Cluster_", cluster_idx, ".csv")
      )) %>%
      dplyr::mutate(Cluster = cluster_idx)
    
    df <- rbind(df, df_tmp)
    
  }

  
  df <- df %>%
    dplyr::mutate(Date = as.Date(Date))%>%
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
    width = 1900,
    height = 800
  )
  
  print({
    extra.calendarHeat(
      dates =  df$Date,
      values = df$severity,
      pvalues = df$Cluster,
      pch.symbol = c(0:5),
      cex.symbol = 0.7,
      fontfamily = font_family,
      col.symbol = 'gray30',
      color = 'palette'
    )
  })
  
  dev.off()
  
  
  df_diagnosis <-
    rbind(
      df_diagnosis,
      df %>% dplyr::filter(severity >= 6) %>% dplyr::mutate(context = context_idx)
    )
  
  
}
