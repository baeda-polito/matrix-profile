#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
source("utils_functions.R")

library(ggplot2)
library(dplyr)
library(magrittr)
library(tidyr)
library(scales)
library(tidyverse)
library(ggpubr)         # arrange plots
library(ggtext)         # annotate text


df <- read.csv(file.path(dirname(dirname(getwd())), 
                         "Roberto Chiosa", 
                         "CMP",
                         "Polito_Usecase", 
                         "demo_data", 
                         "df_univariate_full.csv"),
               sep = ';', dec = ","
) %>%
  dplyr::mutate(timestamp = as.POSIXct(CET, "%Y-%m-%d %H:%M:%S", tz = "GMT"), # occhio al cambio ora
                value = as.numeric(Power_total)
  ) %>%
  dplyr::filter(timestamp >"2015-05-01" & timestamp <"2015-06-10") %>%
  dplyr::select(timestamp, value)


fontsize <- 10
linesize <- 0.7

# # identification of subsequences
# ggplot(df) +
#   geom_line(
#     aes(x = timestamp, y = value),
#     color = "blue",
#     size = linesize
#   ) + 
#   geom_line(
#     data = df %>% filter(timestamp >= "2015-05-03 00:00:00",
#                          timestamp <= "2015-05-04 00:00:00") ,
#     aes(x = timestamp, y = value),
#     color = "red",
#     size = linesize
#   )+
#   geom_line(
#     data = df %>% filter(timestamp >= "2015-05-17 00:00:00",
#                          timestamp <= "2015-05-18 00:00:00") ,
#     aes(x = timestamp, y = value),
#     color = "red",
#     size = linesize
#   )+
#   geom_line(
#     data = df %>% filter(timestamp >= "2015-06-04 15:00:00",
#                          timestamp <= "2015-06-05 15:00:00") ,
#     aes(x = timestamp, y = value),
#     color = "red",
#     size = linesize
#   )



seq1 = df %>% filter(timestamp >= "2015-05-03 01:00:00",
                     timestamp <= "2015-05-04 01:00:00")  %>% select(value) 
seq2 = df %>% filter(timestamp >= "2015-05-17 01:00:00",
                     timestamp <= "2015-05-18 01:00:00")  %>% select(value)
seq3 = df %>% filter(timestamp >= "2015-06-04 14:00:00",
                     timestamp <= "2015-06-05 14:00:00")  %>% select(value)

L = dim(seq1)[1]
#########
df_seq <- data.frame(
  value = rbind(seq1, seq2, seq3),
  value_z = c(znorm(seq1$value), znorm(seq2$value), znorm(seq3$value)),  
  str = c(rep("Subsequence 1", L), rep("Subsequence 2", L), rep("Subsequence 3", L)) ,
  index = c(seq(L), seq(L), seq(L)) 
)

# identification of subsequences
fig_pure <- ggplot(df_seq) +
  geom_line(
    aes(x = index, y = value, group = str,   color = str),
    size = linesize
    
  ) + 
  scale_color_brewer(palette = "Set1") +
  theme_classic() +
  theme(
    text = element_text(family = font_family),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.background = element_rect(fill =  "transparent"),
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    legend.background = element_rect(fill = "transparent", color = NA), # bg of the plot
  ) +
  scale_x_continuous(limits = c(1, L), expand = c(0, 0))



# identification of subsequences
fig_z <- ggplot(df_seq) +
  geom_line(
    aes(x = index, y = value_z, group = str,   color = str),
    size = linesize
    
  ) + 
  theme_classic() +
  scale_color_brewer(palette = "Set1") +
  theme(
    text = element_text(family = font_family),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.background = element_rect(fill =  "transparent"),
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    legend.background = element_rect(fill = "transparent", color = NA), # bg of the plot
  ) +
  scale_x_continuous(limits = c(1, L), expand = c(0, 0))


fig <-  ggarrange(
  fig_pure, fig_z,
  ncol = 2,
  nrow = 1,
  widths = c(3,3),
  align = "v",
  common.legend = TRUE,
  legend="top"
)


dev.new()
annotate_figure(fig,
                # top = text_grob(paste("A", "discovery window profile"), color = "black", face = "bold", size = 13,  family = font_family),
                left = text_grob("Not Normalized Power [kW]", color = "black", size = 11, rot = 90,  family = font_family),
                right = text_grob("Z-Normalized Power [-]", color = "black",  size = 11, rot = 90,  family = font_family),
                bottom = text_grob("Obs. Index", color = "black",  size = 11,  family = font_family)
                
)


ggsave(filename = file.path("Polito_Usecase", "figures", "demo", "znorm.png"), width = 7, height = 3.5, dpi = dpi )

dev.off()

############  D. De Paepe et al. FIG 1

L = 50
seq1 = 1 + runif(L)
seq2 = 6 + runif(L)
distance1 <- dist(rbind(seq1,seq2) , method = "euclidean")

df_seq <- data.frame(
  value = c(seq1, seq2),
  value_z = c(znorm(seq1), znorm(seq2)),  
  str = c(rep("Subsequence 1", L), rep("Subsequence 2", L)) ,
  index = c(seq(L), seq(L)) 
)

# identification of subsequences
fig_pure <- ggplot(df_seq) +
  geom_line(
    aes(x = index, y = value, group = str,   color = str),
    size = linesize
    
  ) + 
  scale_color_brewer(palette = "Set1") +
  theme_classic() +
  theme(
    text = element_text(family = font_family),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.background = element_rect(fill =  "transparent"),
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    legend.background = element_rect(fill = "transparent", color = NA), # bg of the plot
  ) +
  scale_x_continuous(limits = c(0, L), expand = c(0, 0)) + 
  scale_y_continuous(limits = c(0, 14), expand = c(0, 0))



# identification of subsequences
fig_z <- ggplot(df_seq) +
  geom_line(
    aes(x = index, y = value_z, group = str,   color = str),
    size = linesize
    
  ) + 
  theme_classic() +
  scale_color_brewer(palette = "Set1") +
  theme(
    text = element_text(family = font_family),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.background = element_rect(fill =  "transparent"),
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    legend.background = element_rect(fill = "transparent", color = NA), # bg of the plot
  ) +
  scale_x_continuous(limits = c(0, L), expand = c(0, 0))+ 
  scale_y_continuous(limits = c(-2.5, 2.5), expand = c(0, 0))

seq1 = seq1 + seq(L)/7 
seq2 = seq2 + seq(L)/7 
distance2 <- dist(rbind(seq1,seq2) , method = "euclidean")

df_seq <- data.frame(
  value = c(seq1, seq2),
  value_z = c(znorm(seq1), znorm(seq2)),  
  str = c(rep("Subsequence 1", L), rep("Subsequence 2", L)) ,
  index = c(seq(L), seq(L)) 
)

# identification of subsequences
fig_pure1 <- ggplot(df_seq) +
  geom_line(
    aes(x = index, y = value, group = str,   color = str),
    size = linesize
    
  ) + 
  scale_color_brewer(palette = "Set1") +
  theme_classic() +
  theme(
    text = element_text(family = font_family),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.background = element_rect(fill =  "transparent"),
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    legend.background = element_rect(fill = "transparent", color = NA), # bg of the plot
  ) +
  scale_x_continuous(limits = c(0, L), expand = c(0, 0))+ 
  scale_y_continuous(limits = c(0, 14), expand = c(0, 0))



# identification of subsequences
fig_z1 <- ggplot(df_seq) +
  geom_line(
    aes(x = index, y = value_z, group = str,   color = str),
    size = linesize
    
  ) + 
  theme_classic() +
  scale_color_brewer(palette = "Set1") +
  theme(
    text = element_text(family = font_family),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.background = element_rect(fill =  "transparent"),
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    legend.background = element_rect(fill = "transparent", color = NA), # bg of the plot
  ) +
  scale_x_continuous(limits = c(0, L), expand = c(0, 0))+ 
  scale_y_continuous(limits = c(-2.5, 2.5), expand = c(0, 0))



fig <-  ggarrange(
  fig_pure,fig_pure1, fig_z, fig_z1,
  ncol = 2,
  nrow = 2,
  labels = c("","",paste("d =",round(distance1,2)), paste(" d =",round(distance2,2) )),
  widths = c(3,3),
  align = "v"
)


dev.new()
annotate_figure(fig,
                # top = text_grob(paste("A", "discovery window profile"), color = "black", face = "bold", size = 13,  family = font_family),
                #left = text_grob("Not Normalized Power [kW]", color = "black", size = 11, rot = 90,  family = font_family),
                #right = text_grob("Z-Normalized Power [-]", color = "black",  size = 11, rot = 90,  family = font_family),
                bottom = text_grob("Obs. Index", color = "black",  size = 11,  family = font_family)
                
)


ggsave(filename = file.path("Polito_Usecase", "figures", "demo", "znorm_effects.png"), width = 7, height = 3.5, dpi = dpi )

dev.off()
