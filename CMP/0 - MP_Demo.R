# HEADER --------------------------------------------
#
# Author: Roberto Chiosa
# Copyright © Roberto Chiosa, 2022
# Email:  roberto.chiosa@polito.it
# 
# Date: 2022-01-26
#
# Script Name: ~/Desktop/matrix-profile/CMP/0 - MP_Demo.R
#
# Script Description:
# 
# In this script evidences of the limits of the MP method applied on energy 
# time series are shown by generating 2 figures
#
# Notes:
# 
# The script is not well optimized but works
#
#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
source("utils_functions.R")

library(ggplot2)
library(dplyr)
import::from(magrittr, '%>%')
library(tidyr)
library(scales)
library(tidyverse)
library(ggpubr)         # arrange plots
library(ggtext)         # annotate text


figma_palette <- c("#5EE393", "#0074FF")

df <-
  read.csv(
    file.path("Polito_Usecase", "demo_data", "df_univariate_full.csv"),
    sep = ';',
    dec = ","
  ) %>%
  dplyr::mutate(
    timestamp = as.POSIXct(CET, "%Y-%m-%d %H:%M:%S", tz = "GMT"),
    # occhio al cambio ora
    value = as.numeric(Power_total)
  ) %>%
  dplyr::filter(timestamp > "2015-05-11" &
      timestamp < "2015-06-10") %>%
  dplyr::select(timestamp, value) %>%
  # add subsequences
  mutate(
    tag =
      ifelse(
        timestamp >= "2015-05-17 01:30:00" &
          timestamp <= "2015-05-18 01:30:00",
        "Subsequence 1",
        ifelse(
          timestamp >= "2015-06-04 14:00:00" &
            timestamp <= "2015-06-05 14:00:00",
          "Subsequence 2",
          NA
        )
      ),
    tag = as.factor(tag)
  )


############  ALL
{
  # identification of subsequences
  
  fig_all <- ggplot(df) +
    theme_classic() +
    geom_line(
      aes(x = timestamp, y = value),
      color = "gray",
      size = 0.5,
      show.legend = F
    ) +
    geom_line(
      data = df %>% filter(!is.na(tag)),
      aes(x = timestamp, y = value, color = tag),
      size = 0.5
    ) +
    labs(y = "Power [kW]", x = "Date")+
    scale_color_manual(values = figma_palette) +
    theme(
      text = element_text(family = font_family),
      #axis.title.x = element_blank(),
      #axis.title.y = element_text(size =fontsize_smaller),
      #axis.title.y = element_blank(),
      panel.background = element_rect(fill =  background_fill),
      plot.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_blank(),
      legend.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
    ) +
    scale_x_datetime(
      expand = c(0, 0),
      date_breaks = "3 days",
      date_labels = "%m-%d"
    )
  
  
  L = 97
  
  df_seq <- df %>%
    filter(!is.na(tag)) %>%
    group_by(tag) %>%
    mutate(value_z = znorm(value))
  
  df_seq$index <- c(seq(L), seq(L))
  
  
  # identification of subsequences
  fig_pure <- ggplot(df_seq) +
    geom_line(aes(
      x = index,
      y = value,
      group = tag,
      color = tag
    ),
      size = 0.5) +
    labs(y = "Power [kW]", x = "Observations")+
    scale_color_manual(values = figma_palette) +
    theme_classic() +
    theme(
      text = element_text(family = font_family),
      #axis.title.x = element_blank(),
      #axis.title.y = element_text(size =fontsize_smaller),
      #axis.title.y = element_blank(),
      panel.background = element_rect(fill =  background_fill),
      plot.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_blank(),
      legend.background = element_blank()
    ) +
    scale_x_continuous(limits = c(1, L), expand = c(0, 0))
  
  
  # identification of subsequences
  fig_z <- ggplot(df_seq) +
    geom_line(aes(
      x = index,
      y = value_z,
      group = tag,
      color = tag
    ),
      size = 0.5) +
    labs(y = "Z-Normalized Power [-]", x = "Observations")+
    theme_classic() +
    scale_color_manual(values = figma_palette) +
    theme(
      text = element_text(family = font_family),
      #axis.title.x = element_blank(),
      #axis.title.y = element_text(size =fontsize_smaller),
      #axis.title.y = element_blank(),
      panel.background = element_rect(fill =  background_fill),
      plot.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_blank(),
      legend.background = element_blank()
    ) +
    scale_x_continuous(limits = c(1, L), expand = c(0, 0))
  
  
  fig <- ggarrange(
    fig_all,
    ggarrange(
      fig_z,
      fig_pure,
      ncol = 2,
      widths = c(3, 3),
      align = "v",
      legend = "none"
    ),
    ncol = 1,
    nrow = 2,
    widths = c(1),
    align = "h",
    common.legend = TRUE,
    legend = "top"
  )
  
  
  
  
  dev.new()
  #annotate_figure(fig
  # top = text_grob(paste("A", "discovery window profile"), color = "black", face = "bold", size = 13,  family = font_family),
  #right = text_grob("Not Normalized Power [kW]", color = "black", size = 11, rot = 90,  family = font_family),
  #left = text_grob("Z-Normalized Power [-]", color = "black",  size = 11, rot = 90,  family = font_family),
  #bottom = text_grob("Obs. Index", color = "black",  size = 11,  family = font_family)
  
  #)
  
  fig
  
  ggsave(
    filename = file.path("Polito_Usecase", "figures", "demo", "znorm.jpg"),
    width = 11,
    height = 6,
    dpi = dpi,
    bg = background_fill
  )
  
  dev.off()
  }

############  D. De Paepe et al. FIG 1
{
  set.seed(123)
  L = 40
  seq1 = 1 + runif(L)
  seq2 = 6 + runif(L)
  distance1 <-
    dist(rbind(znorm(seq1), znorm(seq2)) , method = "euclidean")
  
  df_seq <- data.frame(
    value = c(seq1, seq2),
    value_z = c(znorm(seq1), znorm(seq2)),
    str = c(rep("Subsequence 1", L), rep("Subsequence 2", L)) ,
    index = c(seq(L), seq(L))
  )
  
  # identification of subsequences
  fig_pure <- ggplot(df_seq) +
    geom_line(aes(
      x = index,
      y = value,
      group = str,
      color = str
    ),
      size = 0.5) +
    labs(y = "Not normalized [-]")+
    scale_color_manual(values = figma_palette) +
    theme_classic() +
    theme(
      text = element_text(family = font_family),
      axis.title.x = element_blank(),
      # axis.title.y = element_blank(),
      panel.background = element_rect(fill =  background_fill),
      plot.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position = "none",
      legend.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
    ) +
    scale_x_continuous(limits = c(0, L), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 14), expand = c(0, 0))
  
  
  
  # identification of subsequences
  fig_z <- ggplot(df_seq) +
    geom_line(aes(
      x = index,
      y = value_z,
      group = str,
      color = str
    ),
      size = 0.5) +
    theme_classic() +
    labs(y = "Normalized [-]")+
    scale_color_manual(values = figma_palette) +
    theme(
      text = element_text(family = font_family),
      axis.title.x = element_blank(),
      #axis.title.y = element_blank(),
      panel.background = element_rect(fill =  background_fill),
      plot.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position = "none",
      legend.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
    ) +
    scale_x_continuous(limits = c(0, L), expand = c(0, 0)) +
    scale_y_continuous(limits = c(-2.5, 2.5), expand = c(0, 0))
  
  seq1 = seq1 + seq(L) / 7
  seq2 = seq2 + seq(L) / 7
  distance2 <-
    dist(rbind(znorm(seq1), znorm(seq2)) , method = "euclidean")
  
  df_seq <- data.frame(
    value = c(seq1, seq2),
    value_z = c(znorm(seq1), znorm(seq2)),
    str = c(rep("Subsequence 1", L), rep("Subsequence 2", L)) ,
    index = c(seq(L), seq(L))
  )
  
  # identification of subsequences
  fig_pure1 <- ggplot(df_seq) +
    geom_line(aes(
      x = index,
      y = value,
      group = str,
      color = str
    ),
      size = 0.5) +
    labs(y = "Not normalized [-]")+
    scale_color_manual(values = figma_palette) +
    theme_classic() +
    theme(
      text = element_text(family = font_family),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      panel.background = element_rect(fill =  background_fill),
      plot.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position = "none",
      legend.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
    ) +
    scale_x_continuous(limits = c(0, L), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 14), expand = c(0, 0))
  
  
  
  # identification of subsequences
  fig_z1 <- ggplot(df_seq) +
    geom_line(aes(
      x = index,
      y = value_z,
      group = str,
      color = str
    ),
      size = 0.5) +
    theme_classic() +
    labs(y = "Normalized [-]")+
    scale_color_manual(values = figma_palette) +
    theme(
      text = element_text(family = font_family),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      panel.background = element_rect(fill =  background_fill),
      plot.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position = "none",
      legend.background = element_rect(fill = background_fill, color = NA),
      # bg of the plot
    ) +
    scale_x_continuous(limits = c(0, L), expand = c(0, 0)) +
    scale_y_continuous(limits = c(-2.5, 2.5), expand = c(0, 0))
  
  
  
  fig <-  ggarrange(
    fig_pure,
    fig_pure1,
    fig_z,
    fig_z1,
    ncol = 2,
    nrow = 2,
    #labels = c("", "", paste("d =", round(distance1, 2)), paste(" d =", round(distance2, 2))),
    widths = c(3, 3),
    align = "v"
  )
  
  
  dev.new()
  annotate_figure(fig,
    # top = text_grob(paste("A", "discovery window profile"), color = "black", face = "bold", size = 13,  family = font_family),
    #left = text_grob("Not Normalized Power [kW]", color = "black", size = 11, rot = 90,  family = font_family),
    #right = text_grob("Z-Normalized Power [-]", color = "black",  size = 11, rot = 90,  family = font_family),
    bottom = text_grob(
      "Observations",
      color = "black",
      size = 11,
      family = font_family
    ))
  
  
  ggsave(
    filename = file.path("Polito_Usecase", "figures", "demo", "znorm_effects.jpg"),
    width = 9,
    height = 5,
    dpi = dpi,
    bg = background_fill
  )
  
  dev.off()
}
