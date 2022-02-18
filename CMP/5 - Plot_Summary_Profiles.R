# HEADER --------------------------------------------
#
# Author: Roberto Chiosa
# Copyright © Roberto Chiosa, 2022
# Email:  roberto.chiosa@polito.it
#
# Date: 2022-02-01
#
# Script Name: ~/Desktop/matrix-profile/CMP/5 - Plot_Summary_Profiles.R
#
# Script Description:
#
#
# Notes:
#
#
# LOAD PACKAGES and FUNCTIONS ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("global_vars.R")     # Loads global variables
source("utils_functions.R") # Loads utils functions

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(tidyverse)
library(ggpubr)
import::from(magrittr, "%>%")

{
# # FILTER DATES ------------------------------------
# 
# # load the context decoder dataframe
# df_context_decoder <-
#   read.csv(file.path("Polito_Usecase", "data", "contexts.csv"))
# # list all folders of context
# context_folder_vector <-
#   list.dirs(file.path("Polito_Usecase", "data"))[-1]
# 
# # define empty vector of dates
# dates_df <- data.frame()
# 
# for (context_idx in 1:length(context_folder_vector)) {
#   df <- data.frame()
#   
#   for (cluster_idx in c(1:5)) {
#     df_tmp <-
#       read.csv(file = file.path(
#         context_folder_vector[context_idx],
#         paste0("anomaly_results_Cluster_", cluster_idx, ".csv")
#       )) %>%
#       mutate(Cluster = cluster_idx)
#     
#     df <- rbind(df, df_tmp)
#     
#   }
#   
#   df <- df %>%
#     dplyr::arrange(Date) %>%
#     dplyr::mutate(severity = cmp_score + energy_score) %>%
#     dplyr::filter(severity == 8) %>% 
#     dplyr::mutate(context = gsub("Polito_Usecase/data/", "", context_folder_vector[context_idx])) %>% 
#     dplyr::select(Date, context)
#   
#   dates_df <- rbind(dates_df, df)
# }
# 
# 
# # SECTION ------------------------------------
# 
# df_results <-
#   read.csv(file.path("Polito_Usecase", "data", "anomaly_results.csv"))
# 
# df_corrected <- df_results %>%
#   select(-c(Cluster_1, Cluster_2, Cluster_3, Cluster_4, Cluster_5)) %>%
#   pivot_longer(cols = c(-timestamp),
#     names_to = "context",
#     values_to = "severity") %>%
#   mutate(
#     cluster = ifelse(
#       grepl("Cluster_1.", context),
#       "Cluster 1",
#       ifelse(
#         grepl("Cluster_2.", context),
#         "Cluster 2",
#         ifelse(
#           grepl("Cluster_3.", context),
#           "Cluster 3",
#           ifelse(grepl("Cluster_4.", context),
#             "Cluster 4", "Cluster 5")
#         )
#       )
#     ),
#     cluster = as.factor(cluster),
#     context = gsub("Cluster_1.", "", context),
#     context = gsub("Cluster_2.", "", context),
#     context = gsub("Cluster_3.", "", context),
#     context = gsub("Cluster_4.", "", context),
#     context = gsub("Cluster_5.", "", context),
#     context = as.factor(as.numeric(as.factor(context))),
#     severity = as.factor(severity)
#   ) %>%
#   mutate(context = paste("Context", context),
#     severity = as.numeric(severity)) %>%
#   rename(Date = timestamp)
}


# LOAD POWER ------------------------------------

load <- "Refrigeration_unit2"

 # "Total_Power"        
 # "Allocated"          
 # "Not_allocated"      
 # "Canteen"            
 # "Data_centre"        
 # "Refrigeration_unit2"
 # "Rectory"            
 # "Bar_Ambrogio"       
 # "DIMAT"              
 # "Print_shop"   

# load power data full
df_power <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data",  "polito_raw.csv"),
    sep = ',',
    dec = "."
  ) %>%
  dplyr::select(Date, Time, all_of(load))

colnames(df_power)[3] <- "Total_Power"

ymax <- ceiling(max(df_power$Total_Power)/100)*100

ymax <- 850
# CLUSTER INFO ------------------------------------
df_cluster <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data",  "group_cluster.csv"),
    sep = ',',
    dec = "."
  ) %>%
  rename(Date = timestamp)

for (i in 1:dim(df_cluster)[1]) {
  df_cluster$cluster[i] <-
    colnames(df_cluster)[which(df_cluster[i, ] == TRUE)]
}

df_cluster <- df_cluster %>%
  mutate(cluster = gsub("_", " ", cluster)) %>%
  select(Date, cluster)

df_merged <- merge.data.frame(df_power, df_cluster, by = "Date")

# PLOT ------------------------------------

dates_df <- as.Date(c("2019-08-12", "2019-12-27", "2019-07-15", "2019-07-06","2019-11-10", "2019-07-29", "2019-07-30"))

for (date_idx in 1:length(dates_df)) {
  
  date_plot <- dates_df[date_idx]
  
  cluster_plot <- df_merged %>%
    filter(Date == date_plot) %>%
    select(cluster) %>%
    unique() %>%
    unlist()
  
  dev.new()
  p1 <- ggplot() +
    geom_line(
      data = df_merged %>% filter(cluster == cluster_plot),
      aes(
        x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") ,
        y = Total_Power,
        group = Date
      ) ,
      #color = "#D5D5E0",
      # color = "black",
      # alpha = 0.1,
      # size = 0.5
      color = "#D5D5E0",
      alpha = 0.3,
      size = 0.7
    ) +
    geom_line(
      data = df_merged %>% filter(Date == date_plot),
      aes(
        x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") ,
        y = Total_Power,
        group = Date
      ) ,
      color = "red",
      #alpha = 0.3,
      size = 0.7
    ) +
    scale_x_datetime(
      expand = c(0, 0),
      labels = date_format("%H:%M" , tz = "GMT"),
      breaks = date_breaks("4 hour")
    ) +
    scale_y_continuous(limits = c(0, ymax),
      expand = c(0, 0)) +
    theme_bw() +
    labs(
      title = paste(cluster_plot),
      subtitle = format(as.Date(date_plot), "%A %d %B %Y"),
      x = "Hour" ,
      y = "Power [kW]"
    ) +
    theme_minimal() +
    ggplot2::theme(
      text = element_text(family = font_family),
      axis.ticks = element_line(colour = "black"),
      panel.grid = element_blank(),
      axis.line.y = element_line(colour = "black"),
      axis.line.x = element_line(colour = "black"),
      plot.title = element_text(
        hjust = 0.5,
        size = fontsize_large,
        margin = margin(
          t = 0,
          r = 0,
          b = 0,
          l = 0
        )
      ),
      plot.subtitle = element_text(
        hjust = 0.5,
        size = fontsize_small,
        margin = margin(
          t = 5,
          r = 5,
          b = 10,
          l = 10
        )
      ),
      # legend
      legend.position = "none",
      # legend position on the top of the graph
      # strip.text = element_text(size = 17), # facet wrap title fontsize
      # AXIS X
      #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
      axis.text.x = element_text(
        size = fontsize_small,
        margin = margin(
          t = 5,
          r = 5,
          b = 5,
          l = 5
        ),
        angle = 45,
        vjust = .3
      ),
      # AXIS Y
      #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
      axis.text.y = element_text(
        size = fontsize_small,
        margin = margin(
          t = 5,
          r = 5,
          b = 0,
          l = 5
        ),
        angle = 0,
        vjust = .3
      ),
      # background
      # panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
      #panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
      panel.grid.minor = element_blank(),
      # draws nothing, and assigns no space.
      plot.margin = unit(c(
        plot_margin, plot_margin, plot_margin, plot_margin
      ), "cm")
    )
  
  p1
  
  ggsave(
    filename = file.path(
      "Polito_Usecase",
      "figures",
      "results_profiles",
      paste0(load, "_", date_plot,".png")
    ),
    width = 100,
    height = 80,
    units = "mm",
    dpi = dpi ,
    bg = background_fill
  )
  
  dev.off()
  
}
