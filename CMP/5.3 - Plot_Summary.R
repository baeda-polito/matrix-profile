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


###### RESULT POST PROCESSING
#   - Load results
df <-  read.csv(file.path("Polito_Usecase", "data", "anomaly_results.csv"))


df_corrected <- df %>%
  select(-c(Cluster_1,Cluster_2,Cluster_3,Cluster_4, Cluster_5)) %>%
  pivot_longer(cols=c(-timestamp), names_to = "context", values_to = "values") %>% 
  mutate(
    cluster = ifelse(grepl("Cluster_1.", context),
                     "Cluster 1", 
                     ifelse(grepl("Cluster_2.", context),
                            "Cluster 2",
                            ifelse(grepl("Cluster_3.", context),
                                   "Cluster 3", ifelse(grepl("Cluster_4.", context),
                                     "Cluster 4", "Cluster 5")))),
    cluster = as.factor(cluster),
    context = gsub("Cluster_1.","",context),
    context = gsub("Cluster_2.","",context),
    context = gsub("Cluster_3.","",context),
    context = gsub("Cluster_4.","",context),
    context = gsub("Cluster_5.","",context),
    context = as.factor(as.numeric(as.factor(context))),
    values = as.factor(values)
  )


df_plot <- df_corrected %>% 
  filter(
    values!=0
    #cluster == "Cluster_1"
  ) %>%
  mutate(timestamp = as.Date(timestamp),
         month = lubridate::month(timestamp, label=TRUE),
         day =  lubridate::day(timestamp)
  )


dev.new()

ggplot(df_plot, aes(x = context, y = as.factor(timestamp), fill = values)) +
  geom_tile(color = "white", size = 0.3) +
  #scale_y_continuous(breaks = unique(df_plot$day)) +
  scale_x_discrete() +
  labs(x = "Context", y = "Date") +
  facet_wrap(~cluster, nrow = 1, scales = "free") + 
  scale_fill_manual(name = "Severity",
                    values = brewer_pal(palette = "OrRd")(5)) +
  theme_minimal() +
  ggplot2::theme(
    panel.spacing = unit(3, "lines"),
    text = element_text(family = font_family),
    axis.ticks = element_line(colour = "black"),
    panel.grid = element_blank(),
    legend.position = "top",
    axis.line.y = element_line(colour = "black"),
    axis.line.x = element_line(colour = "black"),
    plot.title = element_text(hjust = 0.5)
  ) +
  ggExtra::removeGrid()


ggsave(filename = file.path("Polito_Usecase", "figures", "anomaly_detection_results_horizontal.jpg"), 
       width = 300, 
       height = 100, 
       units = "mm",
       dpi = dpi ,  bg = background_fill)

dev.off()


