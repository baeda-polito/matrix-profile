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
  list.dirs(file.path("Polito_Usecase", "data"))
# remove unnecessary folders
context_folder_vector <- context_folder_vector[c(2:6)]

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

# save only severity >= 6 for total power
write.csv(
  df_diagnosis,
  file = file.path("Polito_Usecase", "diagnosis", "Total_Power.csv"),
  row.names = FALSE
)


# # these are the dates detected as anomalous
# subloads <- c(
#   "Not_allocated",
#   "Canteen",
#   "Data_centre",
#   "Refrigeration_unit2",
#   "Rectory",
#   #"Bar_Ambrogio",
#   "DIMAT",
#   "Print_shop"
# )
# 
# context_vector <- c(
#   "ctx_from00_00_to01_00_m05_15",
#   "ctx_from05_15_to06_15_m02_30",
#   "ctx_from07_45_to08_45_m06_45",
#   "ctx_from14_30_to15_30_m03_30",
#   "ctx_from18_00_to19_00_m05_00"
# )
# 
# 
# for (subload in subloads) {
#   df_diagnosis <- data.frame()
#   # loop on context
#   for (context_idx in 1:length(context_folder_vector)) {
#     df <- data.frame()
#     # loop on cluster
#     for (cluster_idx in c(1:5)) {
#       df_tmp <-
#         read.csv(
#           file = file.path(
#             "Polito_Usecase",
#             "diagnosis",
#             subload,
#             "data",
#             context_vector[context_idx],
#             paste0("anomaly_results_Cluster_", cluster_idx, ".csv")
#           )
#         ) %>%
#         dplyr::mutate(Cluster = cluster_idx)
#       
#       df <- rbind(df, df_tmp)
#       
#     }
#     
#     df <- df %>%
#       dplyr::arrange(Date) %>%
#       dplyr::mutate(severity = cmp_score + energy_score)
#     
#     df_diagnosis <-
#       rbind(
#         df_diagnosis,
#         df %>% dplyr::mutate(context = context_idx, subload = subload)
#       )
#     
#   }
#   
#   # save only severity >= 6 for total power
#   write.csv(
#     df_diagnosis,
#     file = file.path("Polito_Usecase", "diagnosis", paste0(subload, ".csv")),
#     row.names = FALSE
#   )
#   
# }
# 
# # create severity table
# #
# df_severity_all <-
#   read.csv(file = file.path("Polito_Usecase", "diagnosis", "Total_Power.csv"),) %>%
#   dplyr::select(Date,
#                 severity,
#                 vector_ad_energy_absolute,
#                 vector_ad_energy_relative,
#                 context)
# 
# colnames(df_severity_all)[2:4] <-
#   paste0("Total_Power", c("", "_energy_absolute", "_energy_relative"))
# 
# 
# for (subload in subloads) {
#   df_tmp <-
#     read.csv(file = file.path("Polito_Usecase", "diagnosis", paste0(subload, ".csv")),) %>%
#     dplyr::select(Date,
#                   severity,
#                   vector_ad_energy_absolute,
#                   vector_ad_energy_relative,
#                   context)
#   
#   colnames(df_tmp)[2:4] <-
#     paste0(subload, c("", "_energy_absolute", "_energy_relative"))
#   
#   df_severity_all <-
#     merge.data.frame(df_severity_all,
#                      df_tmp,
#                      by = c("Date", "context"),
#                      all.x = T)
#   
# }
# 
# df_severity_all <-
#   df_severity_all %>% dplyr::filter(Total_Power >= 6) %>%
#   dplyr::select(all_of(c("Date", "context",
#                          "Total_Power",         
#     subloads,
#     
#     paste0(c("Total_Power",subloads), "_energy_absolute"),
#     paste0(c("Total_Power",subloads), "_energy_relative")
#   )))
# 
# 
# # save only severity >= 6 for total power
# write.csv(
#   df_severity_all,
#   file = file.path("Polito_Usecase", "diagnosis","diagnosis_final.csv"),
#   row.names = FALSE
# )


