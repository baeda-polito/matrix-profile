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

figma_blue <- "#22215B"
figma_blue_alpha <- "#D5D5E0"

defined_context <- "ctx_from18_30_to19_30_m04_45"
defined_cluster <- 2
ylabel <- "Energy [kWh]" # Distance
vector_ad <- "vector_ad_energy" # vector_ad_cmp
gesd_limit <- 800

###### Plot Anomaly detection methods
# 1) Box Plot method
# 2) Elbow method
# 3) GESD
# 4) Z-score
# 5) QQ-plot

# load a CMP
group_cmp <-
  read.csv(
    file = file.path(
      "Polito_Usecase",
      "data",
      defined_context,
      paste0("anomaly_results_Cluster_", defined_cluster, ".csv")
    ),
    sep = ',',
    header = T
  )



group_cmp_vector <- group_cmp %>%
  rename(values := vector_ad) %>%
  arrange(desc(values)) %>% # arrange in deschending order
  mutate(index = seq(1:dim(group_cmp)[1]),
    # add index to keep track
    z = (values - mean(values)) / sd(values)) %>%
  select(values, index, z)


# extract some plot variables useful for plots
dist_min <-
  min(group_cmp_vector$values, na.rm = T) # minimum value of distance
dist_max <-
  max(group_cmp_vector$values, na.rm = T) # minimum value of distance
dist_max <-
  round(dist_max / 100) * 100 # round to closest 100 for axis
dist_IQR <-
  max(group_cmp_vector$values, na.rm = T) # get wisker upper

Q1 <- quantile(group_cmp_vector$values, c(0.25))
Q3 <- quantile(group_cmp_vector$values, c(0.75))
IQR <- Q3 - Q1

ymin_bp <-
  max(group_cmp_vector$values[group_cmp_vector$values < Q3 + 1.5 * IQR])

outlier_color <- "red"


plot_boxplot <- group_cmp_vector %>%
  ggplot(aes(y = values)) +
  annotate(
    "rect",
    xmin = -1,
    xmax = 1,
    ymin = ymin_bp,
    ymax = Inf,
    alpha = 0.5,
    fill = figma_blue_alpha
  ) +
  stat_boxplot(geom = 'errorbar',
    width = 0.6,
    color = figma_blue) +
  geom_boxplot(width = 0.6,
    outlier.colour = outlier_color,
    color = figma_blue) +
  
  labs(title = "Boxplot", x = "Group", y = ylabel) +
  scale_x_continuous(expand = c(0, 0), limits = c(-1, 1)) +
  theme_minimal() +
  ggplot2::theme(
    panel.spacing = unit(4, "lines"),
    text = element_text(family = font_family),
    axis.ticks = element_line(colour = "black"),
    panel.grid = element_blank(),
    axis.line.y = element_line(colour = "black"),
    axis.line.x = element_line(colour = "black"),
    plot.title = element_text(hjust = 0.5)
  )

plot_elbow <- ggplot() +
  annotate(
    "rect",
    xmin = 0,
    xmax = 6,
    ymin = -Inf,
    ymax = Inf,
    alpha = 0.5,
    fill = figma_blue_alpha
  ) +
  geom_line(data = group_cmp_vector,
    aes(x = index, y = values),
    color = figma_blue) +
  geom_point(data = group_cmp_vector %>% filter(index < 6),
    aes(x = index, y = values),
    color = outlier_color) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, length(group_cmp_vector$values))) +
  #scale_y_continuous( expand = c(0,0), limits = c(dist_min,dist_max) )+
  labs(title = "Elbow", x = "Index", y = ylabel) +
  theme_minimal() +
  ggplot2::theme(
    panel.spacing = unit(4, "lines"),
    text = element_text(family = font_family),
    axis.ticks = element_line(colour = "black"),
    panel.grid = element_blank(),
    axis.line.y = element_line(colour = "black"),
    axis.line.x = element_line(colour = "black"),
    plot.title = element_text(hjust = 0.5)
  )


plot_zscore <-  ggplot(group_cmp_vector, aes(z)) +
  annotate(
    "rect",
    xmin = 2,
    xmax = Inf,
    ymin = -Inf,
    ymax = Inf,
    alpha = 0.5,
    fill = figma_blue_alpha
  ) +
  annotate(
    "rect",
    xmin = -2,
    xmax = -Inf,
    ymin = -Inf,
    ymax = Inf,
    alpha = 0.5,
    fill = figma_blue_alpha
  ) +
  geom_point(aes(x = z, y = 0), size = 0.5) +
  geom_density(
    na.rm = T,
    color = figma_blue,
    position = "stack",
    adjust = 0.9,
    alpha = 0.1
  ) +
  stat_function(
    fun = dnorm,
    geom = "area",
    alpha = 0.5,
    fill = figma_blue_alpha,
    args = list(
      mean = mean(group_cmp_vector$z),
      sd = sd(group_cmp_vector$z)
    )
  ) +
  #scale_x_continuous( expand = c(0,0), limits = c(-3,3))+
  scale_y_continuous(expand = c(0, 0.1)) +
  labs(title = "Z score", x = "Z-score", y = "Density") +
  theme_minimal() +
  ggplot2::theme(
    panel.spacing = unit(4, "lines"),
    text = element_text(family = font_family),
    axis.ticks = element_line(colour = "black"),
    panel.grid = element_blank(),
    axis.line.y = element_line(colour = "black"),
    axis.line.x = element_line(colour = "black"),
    plot.title = element_text(hjust = 0.5)
  )



plot_gesd <- ggplot() +
  annotate(
    "rect",
    xmin = -Inf,
    xmax = Inf,
    ymin = gesd_limit,
    ymax = Inf,
    alpha = 0.5,
    fill = figma_blue_alpha
  ) +
  geom_line(
    data = group_cmp_vector,
    na.rm = T,
    color = figma_blue,
    aes(x = index, y = values)
  ) +
  geom_point(
    data = group_cmp_vector %>% filter(values > gesd_limit),
    aes(x = index, y = values),
    na.rm = T,
    color = outlier_color
  ) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, length(group_cmp_vector$values))) +
  #scale_y_continuous( expand = c(0,0), limits = c(dist_min,dist_max) )+
  labs(title = "GESD", x = "Index", y = ylabel) +
  theme_minimal() +
  ggplot2::theme(
    panel.spacing = unit(4, "lines"),
    text = element_text(family = font_family),
    axis.ticks = element_line(colour = "black"),
    panel.grid = element_blank(),
    axis.line.y = element_line(colour = "black"),
    axis.line.x = element_line(colour = "black"),
    plot.title = element_text(hjust = 0.5)
  )


plot_qqplot <- ggplot(group_cmp_vector, aes(sample = values)) +
  stat_qq(color = figma_blue, size = 0.5) +
  stat_qq_line(color = figma_blue) +
  #scale_y_continuous(expand = c(0, 0), limits = c(0, dist_max)) +
  scale_x_continuous(expand = c(0, 0), limits = c(-3, 3)) +
  labs(title = "QQ-plot", x = "Z-score", y = ylabel) +
  theme_minimal() +
  ggplot2::theme(
    panel.spacing = unit(4, "lines"),
    text = element_text(family = font_family),
    axis.ticks = element_line(colour = "black"),
    panel.grid = element_blank(),
    axis.line.y = element_line(colour = "black"),
    axis.line.x = element_line(colour = "black"),
    plot.title = element_text(hjust = 0.5)
  ) 




#library(ggpubr)
dev.new()

ggpubr::ggarrange(
  plot_boxplot,
  plot_elbow,
  plot_zscore,
  plot_gesd,
  nrow = 1,
  align = c("h")
)

ggsave(
  filename = file.path("Polito_Usecase", "figures", "anomaly_detection_results.jpg"),
  width = 10,
  height = 2.5,
  dpi = dpi ,
  bg = background_fill
)

dev.off()
