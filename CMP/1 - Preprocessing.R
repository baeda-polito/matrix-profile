# HEADER --------------------------------------------
#
# Author: Roberto Chiosa
# Copyright © Roberto Chiosa, 2022
# Email:  roberto.chiosa@polito.it
# 
# Date: 2022-01-26
#
# Script Name: ~/Desktop/matrix-profile/CMP/1 - Preprocessing.R
#
# Script Description:
#
# This script performs the data pre-processing of the substation C dataset 
# by selecting only total electrical power and outdoor air temperature
#
#
# LOAD PACKAGES and FUNCTIONS ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("global_vars.R")

import::from(magrittr, '%>%')
import::from(dplyr, mutate, select)
library(ggplot2)
library(scales)

###### Load the complete dataframe with
# - Calendar variables
# - Electrical load substation C (main and subloads)
# - Metereological variables

df <-
  read.csv(file.path("Polito_Usecase", "data", "polito_raw.csv"), sep = ',')

# select variables for python analysis of total power
df_py <- df %>%
  dplyr::mutate(timestamp = Date_Time,
                value = Total_Power,
                temp = AirTemp) %>%
  dplyr::select(timestamp, value, temp)

# summary(df_py)

# convert into python readable dataframe and save
write.csv(
  x = df_py,
  file = file.path("Polito_Usecase", "data", "polito.csv"),
  row.names = FALSE
)

###### Explore the dataframe
# - Carpet Plot

dev.new()
df %>%
  dplyr::mutate(Date = as.Date(Date)) %>%
  ggplot2::ggplot() + # crea lo sfondo del grafico
  ggplot2::geom_tile(ggplot2::aes(
    x = as.POSIXct(Time, format = "%H:%M:%S", tz = "Etc/GMT+12"),
    y = Date,
    fill = Total_Power
  )) +
  # tile crea un grafico a tre dimensioni x y z = fill con il data set df_tot
  # aes creates an aestetic property to data
  # as.POSIXct converte le ore a formato standard
  ggplot2::scale_fill_gradientn(
    colours = palette,
    na.value = "white",
    limits = c(0, 800),
    breaks = round(seq(0, 800, by = 150)),
    labels = paste(round(seq(0, 800, by = 150)), "kW")
  ) +
  ggplot2::scale_y_date(
    breaks = scales::date_breaks("1 month"),
    # specify breaks every two months
    labels = scales::date_format("%b", tz = "Etc/GMT+12"),
    # specify format of labels anno mese
    expand = c(0, 0)                                     # espande l'asse y affinche riempia tutto il box in verticale
  ) +
  ggplot2::scale_x_datetime(
    breaks = scales::date_breaks("3 hour"),
    # specify breaks every 4 hours
    labels = scales::date_format(("%H:%M"), tz = "Etc/GMT+12"),
    # specify format of labels ora minuti
    expand = c(0, 0)                                     # espande l'asse x affinche riempia tutto il box in orizzontale
  ) +
  ggplot2::coord_flip() +
  ggplot2::theme_bw() + # white bakground with lines
  ggplot2::theme(
    text = element_text(family = font_family),
    plot.title = element_text(
      hjust = 0.5,
      size = fontsize_large,
      margin = ggplot2::margin(
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
    legend.text = element_text(size = fontsize_small),
    legend.position = "top",
    # legend position on the top of the graph
    legend.key.height = unit(0.4, "cm"),
    # size of legend keys, tacche legenda
    legend.key.width = unit(2.5, "cm"),
    legend.direction = "horizontal",
    # layout of items in legends
    legend.box = "horizontal",
    # arrangement of multiple legends
    legend.title = element_text(vjust = 0.85),
    # title of legend (inherits from title)
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
      angle = 0,
      vjust = .3,
      hjust = 0.5
    ),
    # AXIS Y
    #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.y = element_text(
      size = fontsize_small,
      margin = margin(
        t = 5,
        r = 5,
        b = 5,
        l = 5
      ),
      angle = 0,
      vjust = 0.5
    ),
    panel.background = element_rect(fill = "gray99"),
    # background of plotting area, drawn underneath plot
    panel.grid.major = element_blank(),
    # draws nothing, and assigns no space.
    panel.grid.minor = element_blank(),
    # draws nothing, and assigns no space.
    plot.margin = unit(c(
      plot_margin, plot_margin, plot_margin, plot_margin
    ), "cm")
  ) +
  ggplot2::labs(x = "", y = "", fill = "")

ggplot2::ggsave(
  filename = file.path("Polito_Usecase", "figures", "dataset_carpet.jpg"),
  width = 7,
  height = 4,
  dpi = dpi
)

dev.off()
