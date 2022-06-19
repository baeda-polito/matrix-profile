# HEADER --------------------------------------------
#
# Author: Roberto Chiosa
# Copyright © Roberto Chiosa, 2022
# Email:  roberto.chiosa@polito.it
#
# Date: 2022-01-26
#
# Script Name: ~/Desktop/matrix-profile/CMP/5.2 - Plots_CMP.R
#
# Script Description:
# This script plots the overall CMP and the single CMP for each group
#
# Notes:
#
#
#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
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
library(stringr)
import::from(magrittr, "%>%")
import::from(ggeffects, pretty_range)

# PLOT ------------------------------------
# Plot CMP from extracted data from python
# - Full CMP (loop on contexts)
# - single CMP (loop on groups)

fontsize_rescale_factor <- 4
# load the context decoder dataframe
df_context_decoder <-
  read.csv(file.path("Polito_Usecase", "data", "contexts.csv"))
# list all folders of context
context_folder_vector <-
  list.dirs(file.path("Polito_Usecase", "data"))[-1]

# load cluster definition
group_cluster_df <- read.csv(
  file.path("Polito_Usecase", "data", "group_cluster_fixed.csv"),
  sep = ',',
  header = T
)


# dates in chronological order
dates_cronological <- as.Date(group_cluster_df$timestamp)
# dates in cluster order
dates_clusters <- as.Date(as.vector(
  group_cluster_df %>%
    pivot_longer(c(2:6), values_to = "values", names_to = "names") %>%
    filter(values ==  TRUE) %>%
    arrange(names)
)$timestamp)



for (context_idx in 1:length(context_folder_vector)) {
  # specific folder of context
  context_folder <- context_folder_vector[context_idx]
  
  # decode context string
  context_string_small <-
    gsub("Polito_Usecase/data/", "", context_folder)
  context_string <-
    df_context_decoder$context_string[df_context_decoder$context_string_small == context_string_small]
  
  # list files of context
  folder_files <- list.files(context_folder, pattern = "plot")
  
  
  # FULL CMP Version 1------------------------------------
  
  # plot the full CMP (always named plot_cmp_full.csv)
  df <-
    read.csv(
      file.path(context_folder, "plot_cmp_full.csv"),
      sep = ',',
      header = F
    )
  
  # put dates on row and columns to keep reference of the day
  colnames(df) <- dates_cronological
  rownames(df) <- dates_cronological
  
  df_long <- df %>%
    rownames_to_column("Date") %>%
    pivot_longer(-c(Date), names_to = "Date1", values_to = "values") %>%
    mutate(Date = as.Date(Date),
      Date1 = as.Date(Date1))
  
  # spot the maximum ant the minimum
  legend_breaks <-
    ggeffects::pretty_range(0:round(max(df_long$values,  na.rm = T)), length = 6)
  xy_breaks <- ggeffects::pretty_range(1:dim(df)[1], length = 8)
  
  Sys.setlocale("LC_TIME", "C")
  
  plot_full <- {
    df_long %>%
      ggplot() +
      geom_raster(aes(x = Date1, y = Date, fill = values)) +
      scale_fill_gradientn(
        colours = palette,
        na.value = "white",
        # limits = c(0, maximum_value),
        breaks = legend_breaks,
        labels = legend_breaks
      ) +
      scale_x_date(
        breaks = date_breaks("1 month"),
        # specify breaks every two months
        labels = date_format("%b" , tz = "Etc/GMT+12"),
        # specify format of labels anno mese
        expand = c(0, 0)                                     # espande l'asse y affinche riempia tutto il box in verticale
      ) +
      scale_y_date(
        breaks = date_breaks("1 month"),
        # specify breaks every two months
        labels = date_format("%b" , tz = "Etc/GMT+12"),
        # specify format of labels anno mese
        expand = c(0, 0)                                     # espande l'asse y affinche riempia tutto il box in verticale
      ) +
      theme_bw() +  # white bakground with lines
      coord_fixed(ratio = 1) +
      labs(
        title = paste("CMP for context", context_idx),
        subtitle = context_string,
        x = "" ,
        y = "",
        fill = ""
      ) +                   # axis label
      ggplot2::theme(
        text = element_text(family = font_family),
        plot.title = element_text(
          hjust = 0.5,
          size = fontsize_large + fontsize_rescale_factor,
          margin = margin(
            t = 0,
            r = 0,
            b = 0,
            l = 0
          ),
          
        ),
        plot.subtitle = element_text(
          hjust = 0.5,
          size = fontsize_small + fontsize_rescale_factor,
          margin = margin(
            t = 5,
            r = 5,
            b = 10,
            l = 10
          )
        ),
        # legend
        legend.text = element_text(size = fontsize_small + fontsize_rescale_factor),
        legend.position = "right",
        # legend position on the top of the graph
        legend.key.height = unit(2, "cm"),
        # size of legend keys, tacche legenda
        legend.key.width = unit(0.4, "cm"),
        legend.direction = "vertical",
        # layout of items in legends
        legend.box = "vertical",
        # arrangement of multiple legends
        legend.title = element_blank(),
        # title of legend (inherits from title)
        # strip.text = element_text(size = 17), # facet wrap title fontsize
        # AXIS X
        #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
        axis.text.x = element_text(
          size = fontsize_small + fontsize_rescale_factor,
          margin = margin(
            t = 5,
            r = 5,
            b = 5,
            l = 5
          ),
          angle = 0,
          #vjust=.3, hjust = -0.18,
          
        ),
        # AXIS Y
        #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
        axis.text.y = element_text(
          size = fontsize_small + fontsize_rescale_factor,
          margin = margin(
            t = 5,
            r = 5,
            b = 5,
            l = 5
          ),
          angle = 0,
          #vjust=-1.1
        ),
        # background
        panel.background = element_rect(fill = "gray99"),
        # background of plotting area, drawn underneath plot
        panel.grid.major = element_blank(),
        # draws nothing, and assigns no space.
        panel.grid.minor = element_blank(),
        # draws nothing, and assigns no space.
        plot.margin = unit(
          c(plot_margin, plot_margin, plot_margin, plot_margin),
          "cm"
        )
      )         # margin around entire plot
    
  }
  
  # version 1
  dev.new()
  plot_full
  ggsave(
    filename = file.path(
      gsub("data", "figures", context_folder_vector[context_idx]),
      "cmp_full.jpg"
    ),
    width = 9,
    height = 9,
    dpi = dpi ,
    bg = background_fill
  )
  
  dev.off()
  
  # plot the group CMP and arrange in a list of plot in a single figure
  plot_list <-  list()
  
  # remove not useful files
  cluster_files <-
    folder_files[!folder_files %in% c("plot_cmp_full.csv") &
        !str_detect(folder_files,  "anomaly")]
  
  for (cluster_idx in 1:length(cluster_files)) {
    # read contextual matrix for group
    df1 <-
      read.csv(file.path(context_folder, cluster_files[cluster_idx]),
        sep = ',',
        header = F)
    
    # put dates on row and columns to keep reference of the day
    colnames(df1) <- seq(dim(df1)[1])
    rownames(df1) <- seq(dim(df1)[1])
    
    df_long1 <- df1 %>%
      rownames_to_column("Date") %>%
      pivot_longer(-c(Date), names_to = "Date1", values_to = "values") %>%
      mutate(
        Date = factor(Date, levels = as.character(seq(dim(
          df1
        )[1]))),
        Date1 = factor(Date1, levels = as.character(seq(dim(
          df1
        )[1])))
      )
    
    legend_breaks <-
      ggeffects::pretty_range(0:round(max(df_long1$values,  na.rm = T)), length = 6)
    xy_breaks <-
      ggeffects::pretty_range(1:dim(df1)[1], length = 8)
    plot_title <-
      gsub(pattern = "plot_cmp_", "", cluster_files[cluster_idx])
    plot_title <- gsub(pattern = ".csv", "", plot_title)
    plot_title <- gsub(pattern = "_", " ", plot_title)
    
    
    plot_list[[cluster_idx]] <- df_long1 %>%
      ggplot() +
      geom_raster(aes(x = Date1, y = Date, fill = values)) +
      scale_fill_gradientn(
        colours = palette,
        na.value = "white",
        #limits = c(0, max(legend_breaks)),
        breaks = legend_breaks,
        labels = legend_breaks
      ) +
      theme_bw() +  # white bakground with lines
      coord_fixed(ratio = 1) +
      scale_x_discrete(breaks = xy_breaks, expand = c(0, 0)) +
      scale_y_discrete(breaks = xy_breaks, expand = c(0, 0)) +
      labs(
        title = plot_title,
        subtitle = " ",
        x = "" ,
        y = "",
        fill = ""
      ) +                   # axis label
      ggplot2::theme(
        text = element_text(family = font_family),
        plot.title = element_text(
          hjust = 0.5,
          size = fontsize_large + fontsize_rescale_factor,
          margin = margin(
            t = 0,
            r = 0,
            b = 0,
            l = 0
          ),
          
        ),
        plot.subtitle = element_text(
          hjust = 0.5,
          size = fontsize_small + fontsize_rescale_factor,
          margin = margin(
            t = 5,
            r = 5,
            b = 10,
            l = 10
          )
        ),
        # legend
        legend.text = element_text(size = fontsize_small + fontsize_rescale_factor),
        legend.position = "right",
        # legend position on the top of the graph
        legend.key.height = unit(1.5, "cm"),
        # size of legend keys, tacche legenda
        legend.key.width = unit(0.4, "cm"),
        legend.direction = "vertical",
        # layout of items in legends
        legend.box = "vertical",
        # arrangement of multiple legends
        legend.title = element_blank(),
        # title of legend (inherits from title)
        # strip.text = element_text(size = 17), # facet wrap title fontsize
        # AXIS X
        #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
        axis.text.x = element_text(
          size = fontsize_small + fontsize_rescale_factor,
          margin = margin(
            t = 5,
            r = 5,
            b = 5,
            l = 5
          ),
          angle = 0
        ),
        # AXIS Y
        #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
        axis.text.y = element_text(
          size = fontsize_small + fontsize_rescale_factor,
          margin = margin(
            t = 5,
            r = 5,
            b = 5,
            l = 5
          ),
          angle = 0
        ),
        # background
        panel.background = element_rect(fill = "gray99"),
        # background of plotting area, drawn underneath plot
        panel.grid.major = element_blank(),
        # draws nothing, and assigns no space.
        panel.grid.minor = element_blank(),
        # draws nothing, and assigns no space.
        plot.margin = unit(
          c(plot_margin, plot_margin, plot_margin, plot_margin),
          "cm"
        )
      )         # margin around entire plot
    
    
  }
  
  # version 1 horizontal
  dev.new()
  ggarrange(plotlist = plot_list,
    nrow = 1,
    align = c("h"))
  ggsave(
    filename = file.path(
      gsub("data", "figures", context_folder_vector[context_idx]),
      "cmp_groups_horizontal.jpg"
    ),
    width = 23,
    height = 5.5,
    dpi = dpi ,
    bg = background_fill
  )
  dev.off()
  
  # version 2 compact
  dev.new()
  ggarrange(plotlist = plot_list)
  ggsave(
    filename = file.path(
      gsub("data", "figures", context_folder_vector[context_idx]),
      "cmp_groups_compact.jpg"
    ),
    width = 14,
    height = 9,
    dpi = dpi ,
    bg = background_fill
  )
  dev.off()
  
  
}
