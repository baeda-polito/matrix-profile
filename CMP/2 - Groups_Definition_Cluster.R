# HEADER --------------------------------------------
#
# Author: Roberto Chiosa
# Copyright © Roberto Chiosa, 2022
# Email:  roberto.chiosa@polito.it
#
# Date: 2022-01-26
#
# Script Name: ~/Desktop/matrix-profile/CMP/2 - Groups_Definition_Cluster.R
#
# Script Description:
#
# This script implements the hierarchical cluster on the dataset by
# identifying the groups for matrix profile splitting and analysis
#
#
# Notes:
#
# A bit messy in the double clustering approach and should be revised
#
#
#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("global_vars.R")     # loads global variables
source("utils_functions.R") # loads utils functions


import::from(magrittr, "%>%")
import::from(dplyr,
  select,
  mutate,
  group_by,
  count,
  across,
  summarise,
  filter,
  arrange)
import::from(tidyr, pivot_wider)
import::from(NbClust, NbClust)
import::from(data.table, data.table)
import::from(mltools, one_hot)
import::from(plyr, ddply)
library(ggplot2)
library(scales)

figures_path <- file.path("Polito_Usecase", "figures", "groups")

plot_clusters <- function(df_power, df_power_wide) {
  df_power <-
    merge.data.frame(df_power, df_power_wide[c("Date", "cluster")])
  centr <-
    ddply(df_power,
      c("cluster", "Time"),
      summarise,
      Total_Power = mean(Total_Power))
  
  # create a counting dataframe
  counted <- df_power %>%
    group_by(cluster) %>%
    count() %>%
    mutate(n = n / 96)
  
  
  # profiles dataframe
  df1_plot <- merge.data.frame(df_power, counted) %>%
    mutate(
      cluster_label = paste("Cluster ", cluster, " (", n, " profiles)", sep = ""),
      cluster_label = as.factor(cluster_label)
    )
  
  # centroid dataframe
  centr_plot <- merge.data.frame(centr, counted) %>%
    mutate(
      cluster_label = paste("Cluster ", cluster, " (", n, " profiles)", sep = ""),
      cluster_label = as.factor(cluster_label)
    )
  
  plot <- ggplot() +
    geom_line(
      data = df1_plot,
      aes(
        x = as.POSIXct(Time, format = "%H:%M:%S", tz = "GMT"),
        y = Total_Power,
        group = Date
      ),
      color = "#D5D5E0",
      alpha = 0.3,
      size = 0.7
    ) +
    geom_line(
      data = centr_plot,
      aes(
        x = as.POSIXct(Time, format = "%H:%M:%S", tz = "GMT"),
        y = Total_Power,
        color = cluster_label
      ),
      size = 1
    ) +
    #scale_color_manual(values = c("#D83C3B", "#3681A9", "#87CD93","#FA9A4E") ) +
    scale_x_datetime(
      expand = c(0, 0),
      labels = date_format("%H:%M", tz = "GMT"),
      breaks = date_breaks("4 hour")
    ) +
    scale_y_continuous(limits = c(0, ceiling(max(
      df1_plot$Total_Power
    ) / 100) * 100),
      expand = c(0, 0)) +
    theme_bw() +
    facet_wrap( ~ cluster_label, nrow = 1, scales = "free") +
    labs(#title = "Daily Profile Cluster Results",
      #subtitle = "Identification of 6 similarity groups for CMP analysis",
      x = "",
      y = "Power [kW]") +
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
        ),
        
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
}

# DATASET PRE-PROCESSING: ------------------------------------
#   - Load "df_calendar" for Date, Day_type and Holiday info
#   - Load "df_power" for clustering
#   - Spread "df_power" into "df_power_wide" for clustering
#   - Select only values in data from "df_power_wide" and put in "cluster_data"

df_calendar <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data", "polito_raw.csv"),
    sep = ',',
    dec = "."
  ) %>%
  select(Date, Day_Type, Holiday) %>%
  unique()

df_power <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data", "polito_raw.csv"),
    sep = ',',
    dec = "."
  ) %>%
  dplyr::select(Date, Time, Total_Power)

df_power_wide <-
  pivot_wider(df_power, names_from = "Time", values_from = "Total_Power")

cluster_data <- select(df_power_wide, -Date)

# CLUSTERING ------------------------------------
#   - "diss_matrix" Dissimilarity matrix with euclidean distance
#   - Set number of clusters
#   - Perform cluster

diss_matrix <- dist(cluster_data, method = "euclidean")

n_clusters <- 6 # supervised
#Nb_res <- NbClust(cluster_data, diss = diss_matrix, distance = NULL, min.nc = 2, max.nc = 8, method = "ward.D2", index = "all")
#n_clusters <- length(unique(Nb_res$Best.partition))

# Do cluster
hcl <- hclust(diss_matrix, method = "ward.D2")

# # plot dendogram
# dev.new()
# png(file = file.path(figures_path, "groups_dendogram.jpg"), bg = "white", width = 900, height = 500)                   # to save automatically image in WD
# plot(hcl, family = font_family)
# rect.hclust(hcl, k = n_clusters, border = "red")
# dev.off()

# add cluster id to total dataframe
df_power_wide$cluster <- cutree(hcl, n_clusters)

# plot horizontal labeled
dev.new()
plot <- plot_clusters(df_power, df_power_wide)
plot
ggsave(
  filename = file.path(figures_path, "groups_clusters_part_1_0.jpg"),
  width = 10,
  height = 3,
  dpi = dpi,
  bg = background_fill
)
dev.off()

# merge with previous to add calendar variables etc
df_power_wide <- merge.data.frame(df_power_wide, df_calendar)

# fix clusters ------------------------------------
# move sunday in 1
df_power_wide <-
  mutate(df_power_wide, cluster = ifelse(Day_Type == 7, 1, cluster))
# move saturday in 3
df_power_wide <-
  mutate(df_power_wide, cluster = ifelse(Day_Type == 6 &
      cluster != 1, 3, cluster))
# merge clusters
df_power_wide <-
  mutate(df_power_wide, cluster = ifelse(cluster == 5 |
      cluster == 6, 4, cluster))

# plot horizontal labeled
dev.new()
plot <- plot_clusters(df_power, df_power_wide)
plot
ggsave(
  filename = file.path(figures_path, "groups_clusters_part_1_1.jpg"),
  width = 10,
  height = 3,
  dpi = dpi,
  bg = background_fill
)
dev.off()

# save only days in clusters
df_power_wide_part1 <- df_power_wide %>%
  filter(cluster == 1 | cluster == 3) %>%
  mutate(cluster = ifelse(cluster == 3, 2, 1))

# DATASET PRE-PROCESSING: ------------------------------------
#   - Load "df_calendar" for Date, Day_type and Holiday info
#   - Load "df_power" for clustering
#   - Spread "df_power" into "df_power_wide" for clustering
#   - Select only values in data from "df_power_wide" and put in "cluster_data"

df_calendar <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data", "polito_raw.csv"),
    sep = ',',
    dec = "."
  ) %>%
  select(Date, Day_Type, Holiday) %>%
  unique()

df_power <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data", "polito_raw.csv"),
    sep = ',',
    dec = "."
  ) %>%
  dplyr::select(Date, Time, Total_Power)

df_power_wide <-
  pivot_wider(df_power, names_from = "Time", values_from = "Total_Power") %>%
  filter(!(Date %in% df_power_wide_part1$Date))


cluster_data <- select(df_power_wide, -Date)

# CLUSTERING ------------------------------------
#   - "diss_matrix" Dissimilarity matrix with euclidean distance
#   - Set number of clusters
#   - Perform cluster

diss_matrix <- dist(cluster_data, method = "euclidean")

Nb_res <-
  NbClust(
    cluster_data,
    diss = diss_matrix,
    distance = NULL,
    min.nc = 2,
    max.nc = 8,
    method = "kmeans",
    index = "silhouette"
  )
n_clusters <- length(unique(Nb_res$Best.partition))


# add cluster id to total dataframe
df_power_wide$cluster <- Nb_res$Best.partition + 2

# merge with previous to add calendar variables etc
df_power_wide <- merge.data.frame(df_power_wide, df_calendar)

# plot horizontal labeled
dev.new()
plot <- plot_clusters(df_power, df_power_wide)
plot
ggsave(
  filename = file.path(figures_path, "groups_clusters_part_2_0.jpg"),
  width = 10,
  height = 3,
  dpi = dpi,
  bg = background_fill
)
dev.off()

df_power_wide_part2 <- df_power_wide


# join results ------------------------------------

df_power_wide_all <-
  rbind(df_power_wide_part1, df_power_wide_part2) %>%
  arrange(Date)

# plot horizontal labeled
dev.new()
plot <- plot_clusters(df_power, df_power_wide_all)
plot
ggsave(
  filename = file.path(figures_path, "groups_clusters_part_2_1.jpg"),
  width = 10,
  height = 3,
  dpi = dpi,
  bg = background_fill
)
dev.off()


# EXPORT RESULTS ------------------------------------
#   - Create a one hot encoding of cluster by date
#   - Convert to Boolean
#   - Save

group_cluster <- data.table(timestamp = df_power_wide_all$Date,
  Cluster = as.factor(df_power_wide_all$cluster)) %>%
  one_hot() %>%
  as.data.frame() %>%
  mutate(across(where(is.numeric), as.logical))

write.csv(
  group_cluster,
  file = file.path("Polito_Usecase", "data", "group_cluster.csv"),
  row.names = FALSE
)
