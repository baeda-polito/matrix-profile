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


df <-  read.csv(file.path("Polito_Usecase", "data", "anomaly_results.csv"))

####### try base r

df_corrected <- df %>%
  # rowwise() %>%
  # mutate(somma = sum(c_across(colnames(df)[6:25])) ) %>%
  # ungroup() %>%
  # filter(somma != 0) %>%
  # arrange(desc(somma))  %>%
  select(-c(Cluster_1,Cluster_2,Cluster_3,Cluster_4)) %>%
  pivot_longer(cols=c(-timestamp), names_to = "context", values_to = "values") %>% 
  mutate(
    cluster = ifelse(grepl("Cluster_1.", context),
                     "Cluster 1", 
                     ifelse(grepl("Cluster_2.", context),
                            "Cluster 2",
                            ifelse(grepl("Cluster_3.", context),
                                   "Cluster 3", "Cluster 4"))),
    cluster = as.factor(cluster),
    context = gsub("Cluster_1.","",context),
    context = gsub("Cluster_2.","",context),
    context = gsub("Cluster_3.","",context),
    context = gsub("Cluster_4.","",context),
    context = as.factor(as.numeric(as.factor(context))),
    values = as.factor(values)
  )

df_plot <- df_corrected %>% 
  # filter(
  #   values!=0,
  #   cluster == "Cluster_1"
  #   ) %>%
  mutate(timestamp = as.Date(timestamp),
         month = lubridate::month(timestamp, label=TRUE),
         day =  lubridate::day(timestamp)
  )

dev.new()

ggplot(df_plot, aes(x = context, y = day, fill = values)) +
  geom_tile(color = "white", size = 0.1) +
  scale_y_continuous(breaks = unique(df_plot$day)) +
  scale_x_discrete() +
  facet_grid( cluster ~ month) +
  scale_fill_manual(name = "Severity",
                    values = brewer_pal(palette = "Reds")(5)) +
  theme_minimal(base_size = 8) +
  labs(x = "Context", y = "Day") +
  theme(
    strip.background = element_rect(colour = "white"),
    axis.ticks = element_blank()
  ) +
  ggExtra::removeGrid()#ggExtra


ggsave(filename = file.path("Polito_Usecase", "figures", "anomaly_detection_resultsV1.jpeg"), 
       width = 210, 
       height = 297, 
       units = "mm",
       dpi = dpi ,  bg = background_fill)

dev.off()


####
df_plot <- df_corrected %>% 
  filter(
    values!=0,
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
  facet_wrap(~cluster, scales = "free") + 
  scale_fill_manual(name = "Severity",
                    values = brewer_pal(palette = "Reds")(5)) +
  theme_minimal() +
  ggplot2::theme(
    text = element_text(family = font_family)
  ) + 
  ggExtra::removeGrid()


ggsave(filename = file.path("Polito_Usecase", "figures", "anomaly_detection_resultsV2_v.jpeg"), 
       width = 200, 
       height = 250, 
       units = "mm",
       dpi = dpi ,  bg = background_fill)

dev.off()


dev.new()

ggplot(df_plot, aes(x = context, y = as.factor(timestamp), fill = values)) +
  geom_tile(color = "white", size = 0.3) +
  #scale_y_continuous(breaks = unique(df_plot$day)) +
  scale_x_discrete() +
  labs(x = "Context", y = "Date") +
  facet_wrap(~cluster, nrow = 1, scales = "free") + 
  scale_fill_manual(name = "Severity",
                    values = brewer_pal(palette = "Reds")(5)) +
  theme_minimal() +
  ggplot2::theme(
    text = element_text(family = font_family)
  ) + 
  ggExtra::removeGrid()


ggsave(filename = file.path("Polito_Usecase", "figures", "anomaly_detection_resultsV2_h.jpeg"), 
       width = 300, 
       height = 100, 
       units = "mm",
       dpi = dpi ,  bg = background_fill)

dev.off()


