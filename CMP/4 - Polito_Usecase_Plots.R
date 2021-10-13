#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(tidyverse)
library(gridExtra)

import::from(magrittr, '%>%')
import::from(dplyr, summarise, across, everything, arrange)

###########
# plot anomaly detection methods methods

group_cmp <-  read.csv(file.path("Polito_Usecase", "data", "ad_data", "group_cmp.csv"), sep = ',', header = F)

group_cmp_vector <- group_cmp %>% 
  summarise(across(everything(), mean, na.rm = T)) %>%
  t() %>% # transpose
  as.data.frame() %>% # back to df 
  rename(values = V1) %>%
  arrange(desc(values)) %>%
  mutate(index = seq(1:dim(group_cmp)[1]),
    z = (values-mean(values))/sd(values) )

dist_min <- min(group_cmp_vector$values, na.rm = T)
dist_max <- max(group_cmp_vector$values, na.rm = T)
dist_max <- round(dist_max/100)*100
dist_IQR <- max(group_cmp_vector$values, na.rm = T)

Q1 <- quantile(group_cmp_vector$values, c(0.25))
Q3 <- quantile(group_cmp_vector$values, c(0.75))
IQR <- Q3-Q1

ymin_bp <- max(group_cmp_vector$values[group_cmp_vector$values < Q3+1.5*IQR])

outlier_color <- "red"

p1 <- group_cmp_vector %>%
  ggplot(aes(y=values)) +
  annotate(
    "rect",
    xmin = -1,
    xmax = 1,
    ymin = ymin_bp,
    ymax = dist_max,
    alpha = 0.5,
    fill = "gray"
  ) +
  stat_boxplot(geom ='errorbar', width = 0.6) +
  geom_boxplot(width = 0.6, outlier.colour = outlier_color) + 
  labs(title = "Boxplot", x = "Group", y = "Distance") +
  scale_x_continuous( expand = c(0,0), limits = c(-1,1))+
  scale_y_continuous( expand = c(0,0), limits = c(dist_min,dist_max) )+
  theme_classic()

p2 <- ggplot() +
  annotate(
    "rect",
    xmin = 0,
    xmax = 10,
    ymin = dist_min,
    ymax = dist_max,
    alpha = 0.5,
    fill = "gray"
  ) +
  geom_line(data = group_cmp_vector, 
    aes(x = index, y=values)) +
  geom_point(data = group_cmp_vector %>% filter(index<10), 
    aes(x = index, y=values), 
    color = outlier_color) +
  scale_x_continuous( expand = c(0,0), limits = c(0,length(group_cmp_vector$values)))+
  scale_y_continuous( expand = c(0,0), limits = c(dist_min,dist_max) )+
  labs(title = "Elbow", x = "Index", y = "Distance")+
  theme_classic()

p3 <-  ggplot(group_cmp_vector, aes(z)) +
  annotate(
    "rect",
    xmin = 2,
    xmax = Inf,
    ymin = -Inf,
    ymax = Inf,
    alpha = 0.5,
    fill = "gray"
  ) +
  annotate(
    "rect",
    xmin = -2,
    xmax = -Inf,
    ymin = -Inf,
    ymax = Inf,
    alpha = 0.5,
    fill = "gray"
  ) +
  geom_density(
    position="stack", 
    adjust = 0.9, 
    alpha = 0.1) +
  stat_function(
    fun = dnorm, 
    geom = "area", 
    alpha = 0.1, 
    fill = "blue",
    args = list(mean = mean(group_cmp_vector$z), 
      sd = sd(group_cmp_vector$z))) + 
  scale_x_continuous( expand = c(0,0), limits = c(-3,3))+
  scale_y_continuous( expand = c(0,0))+
  labs(title = "Z score", x = "Z-score", y = "Density")+
  theme_classic()


p4 <- ggplot() +
  annotate(
    "rect",
    xmin = -Inf,
    xmax = Inf,
    ymin = 80,
    ymax = dist_max,
    alpha = 0.5,
    fill = "gray"
  ) +
  geom_line(data = group_cmp_vector, 
    aes(x = index, y=values)) +
  geom_point(data = group_cmp_vector %>% filter(values>80), 
    aes(x = index, y=values), 
    color = outlier_color) +
  scale_x_continuous( expand = c(0,0), limits = c(0,length(group_cmp_vector$values)))+
  scale_y_continuous( expand = c(0,0), limits = c(dist_min,dist_max) )+
  labs(title = "GESD", x = "Index", y = "Distance")+
  theme_classic()

p5 <- ggplot(group_cmp_vector, aes(sample = values)) +
  stat_qq() +
  stat_qq_line()+
  scale_y_continuous( expand = c(0,0), limits = c(0,dist_max) )+
  scale_x_continuous( expand = c(0,0), limits = c(-3,3))+
  labs(title = "QQ-plot", x = "Z-score", y = "Distance")+
  theme_classic()

#library(ggpubr)
dev.new()

ggarrange(p1,p2,p3,p4, p5, nrow = 1, align = c("h"))

ggsave(filename = file.path("Polito_Usecase", "figures", "anomaly_detection_results.jpeg"),
  width = 12, height = 3, dpi = dpi ,  bg = background_fill)

dev.off()

