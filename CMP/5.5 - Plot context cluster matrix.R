#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(tidyverse)
library(ggpubr)
import::from(magrittr, "%>%")
library("RColorBrewer")
library(gplots)


for (i in c(1:5)) {
  df <-
    read.csv(file.path(
      "Polito_Usecase",
      "data",
      "ctx_from00_00_to01_00_m05_15",
      paste0("anomaly_results_Cluster_", i, ".csv")
    )) %>%
    select(-X)
  
  
  
  col <- c("white", brewer.pal(4, "OrRd"))
  # The mtcars dataset:
  data <- as.matrix(df[, c(2:4)])
  rownames(data) <- df$Date
  colnames(data) <- c("cmp", "energy", "temp")
  
  
  dev.new()
  
  png(
    filename = file.path(
      "Polito_Usecase",
      "figures",
      "ctx_from00_00_to01_00_m05_15",
      paste0("anomaly_results_Cluster_", i, ".png")
    ),
    width = 400,
    height = 600*dim(data)[1]/75
  )
  
  
  heatmap.2(
    data,
    col = col,
    colsep = c(1:dim(data)[2]),
    rowsep = (1:dim(data)[1]),
    sepwidth = c(0.1, 0.1),
    sepcolor = "white",
    trace = "none",
    Rowv = T,
    Colv = F,
    scale = "none",
    dendrogram = "none",
    key = F,
    cexCol = 1,
    xlab = "Score",
    ylab = "Date",
    # lhei = c(0.05, 5),
    margins = c(5, 10)
  )
  
  dev.off()
}
