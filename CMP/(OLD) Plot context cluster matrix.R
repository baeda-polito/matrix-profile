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


# load the context decoder dataframe
df_context_decoder <-
  read.csv(file.path("Polito_Usecase", "data", "contexts.csv"))
# list all folders of context
context_folder_vector <-
  list.dirs(file.path("Polito_Usecase", "data"))[-1]


for (context_idx in 1:length(context_folder_vector)) {
  
  # specific folder of context
  context_folder <- context_folder_vector[context_idx]
  
  # decode context string
  context_string_small <-
    gsub("Polito_Usecase/data/", "", context_folder)
  
  context_string <-
    df_context_decoder$context_string[df_context_decoder$context_string_small == context_string_small]
  
  
  df <-
    read.csv(file.path(
      context_folder,
      paste0("anomaly_results_Cluster_", context_idx, ".csv")
    )) 
  
  col <- c("white", brewer.pal(4, "OrRd"))
  # The mtcars dataset:
  data <- as.matrix(df[, c(2:4)])
  rownames(data) <- df$Date
  colnames(data) <- c("cmp", "energy", "temp")
  
  
  dev.new()
  
  png(
    filename = file.path(
      gsub("data", "figures",context_folder),
      paste0("anomaly_results_Cluster_", context_idx, ".png")
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
