#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(tidyverse)

library(tidyverse)
library(gridExtra)

import::from(magrittr, '%>%')
import::from(dplyr, summarise, across, everything, arrange)

###########
# plot methods

group_cmp <-  read.csv(file.path("Polito_Usecase", "data", "ad_data", "group_cmp.csv"), sep = ',', header = F)

group_cmp_vector <- group_cmp %>% 
  summarise(across(everything(), mean, na.rm = T)) %>%
  t() %>% # transpose
  as.data.frame() %>% # back to df 
  rename(values = V1) %>%
  arrange(desc(values)) %>%
  mutate(index = seq(1:dim(group_cmp)[1]),
         z = (values-mean(values))/sd(values) )

p1 <- group_cmp_vector %>%
  ggplot(aes(y=values)) +
  stat_boxplot(geom ='errorbar', width = 0.6) +
  geom_boxplot(width = 0.6)+ 
  labs(x = "Group", y = "Distance") +
  xlim(c(-1,1)) +
  theme_classic()

p2 <- group_cmp_vector %>%
  ggplot() +
  geom_line(aes(x = index, y=values)) +
  geom_point(aes(x = index, y=values), size = 2, fill = "white", colour = "black")+ 
  labs(x = "Index", y = "Distance")+
  theme_classic()


             
p3 <-  ggplot(group_cmp_vector, aes(z)) +
  geom_density(position="stack", adjust = 1, fill = "red", alpha = 0.1) +
  stat_function(fun = dnorm, args = list(mean = mean(group_cmp_vector$z), 
                                         sd = sd(group_cmp_vector$z))) + 
  xlim(c(-3,3)) +
  labs(x = "Z-score", y = "Distance")+
  theme_classic()


p4 <- ggplot(group_cmp_vector, aes(sample = values)) +
  stat_qq() +
  stat_qq_line()+  xlim(c(-3,3)) + 
  labs(x = "Z-score", y = "Distance")+
  theme_classic()

library(ggpubr)
dev.new()

ggarrange(p1,p2,p3,p4, nrow = 1, align = c("h"))

ggsave(filename = file.path("Polito_Usecase", "figures", "anomaly_detection_results.jpeg"),
       width = 10, height = 2, dpi = dpi ,  bg = background_fill)

dev.off()


###########

df <-  read.csv(file.path("Polito_Usecase", "data", "ctx_from05_15_to06_15_m02_30", "plot_cmp_full.csv"), sep = ',', header = F)


colnames(df) <- as.Date(read.csv(file.path("Polito_Usecase", "data", "polito_cluster.csv"), sep = ',', header = T)[,1])
rownames(df) <- as.Date(read.csv(file.path("Polito_Usecase", "data", "polito_cluster.csv"), sep = ',', header = T)[,1])

df_long <- df %>% 
  rownames_to_column("Date") %>%
  pivot_longer(-c(Date), names_to = "Date1", values_to = "values") %>%
  mutate(Date = as.Date(Date),
         Date1 = as.Date(Date1),
  )

# spot the maximum ant the minimum

maximum_value <- round(max(df_long$values,  na.rm = T), digits = -2)


dev.new() 
df_long %>%
  ggplot() + 
  geom_raster(aes(x=Date1, y=Date, fill=values)) +
  scale_fill_gradientn(
    colours = palette,
    na.value = "white",
    limits = c(0, maximum_value), 
    breaks = round(seq(0,maximum_value, by = 150)),
    labels = round(seq(0,maximum_value, by = 150))
  )+
  scale_x_date(
    breaks = date_breaks("1 month"),                    # specify breaks every two months
    labels = date_format("%b" , tz = "Etc/GMT+12"),  # specify format of labels anno mese
    expand = c(0,0)                                     # espande l'asse y affinche riempia tutto il box in verticale
  ) +
  scale_y_date(
    breaks = date_breaks("1 month"),                    # specify breaks every two months
    labels = date_format("%b" , tz = "Etc/GMT+12"),  # specify format of labels anno mese
    expand = c(0,0)                                     # espande l'asse y affinche riempia tutto il box in verticale
  ) +
  theme_bw() +  # white bakground with lines
  coord_fixed(ratio = 1) + 
  labs( title = "CMP for All Groups",
        subtitle = "Context 04:00-06:00 AM with m = 2:30h (10 observations)",
        x = "" , y = "", fill = "") +                   # axis label
  ggplot2::theme(
    text = element_text(family = font_family),
    plot.title = element_text(hjust = 0.5, size = fontsize_large, margin = margin(t = 0, r = 0, b = 0, l = 0), ),
    plot.subtitle = element_text(hjust = 0.5, size = fontsize_small, margin = margin(t = 5, r = 5, b = 10, l = 10)),
    # legend
    legend.text = element_text(size = fontsize_small),
    legend.position = "right",                     # legend position on the top of the graph
    legend.key.height = unit(2, "cm"),          # size of legend keys, tacche legenda
    legend.key.width = unit(0.4, "cm"),
    legend.direction = "vertical",             # layout of items in legends
    legend.box = "vertical",                   # arrangement of multiple legends
    legend.title = element_blank(),      # title of legend (inherits from title)
    # strip.text = element_text(size = 17), # facet wrap title fontsize
    # AXIS X
    #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.x = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), 
                               angle = 0, vjust=.3, hjust = -0.18),
    # AXIS Y
    #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.y = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), 
                               angle = 0, vjust=-1.1),
    # background
    panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
    panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
    panel.grid.minor = element_blank(),            # draws nothing, and assigns no space.
    plot.margin = unit(c(plot_margin,plot_margin,plot_margin,plot_margin), "cm")
  )         # margin around entire plot

ggsave(filename = file.path("Polito_Usecase", "figures","ctx_from05_15_to06_15_m02_30", "cmp_context_R.png"), width = 6, height = 5.5, dpi = dpi )

dev.off()




# spot the maximum ant the minimum

df1 <-  read.csv(file.path("Polito_Usecase", "data", "ctx_from05_15_to06_15_m02_30", "plot_cmp_Cluster_2.csv"), sep = ',', header = F)



colnames(df1) <- seq(dim(df1)[1])
rownames(df1) <- seq(dim(df1)[1])

df_long1 <- df1 %>% 
  rownames_to_column("Date") %>%
  pivot_longer(-c(Date), names_to = "Date1", values_to = "values") %>%
  mutate(Date = factor(Date, levels = as.character( seq(dim(df1)[1])) ),
         Date1 = factor(Date1, levels = as.character( seq(dim(df1)[1])) )
  )
# spot the maximum ant the minimum

maximum_value <- round(max(df_long1$values,  na.rm = T), digits = -2)


dev.new() 
df_long1 %>%
  ggplot() + 
  geom_raster(aes(x=Date1, y=Date, fill=values)) +
  scale_fill_gradientn(
    colours = palette,
    na.value = "white",
    limits = c(0, maximum_value), 
    breaks = round(seq(0,maximum_value, by = 100)),
    labels = round(seq(0,maximum_value, by = 100))
  )+
  theme_bw() +  # white bakground with lines
  coord_fixed(ratio = 1) + 
  scale_x_discrete(expand = c(0,0)) +
  scale_y_discrete(expand = c(0,0)) +
  labs( title = "CMP for Cluster 2",
        subtitle = "Context 04:00-06:00 AM with m = 2:30h (10 observations)",
        x = "" , y = "", fill = "") +                   # axis label
  ggplot2::theme(
    text = element_text(family = font_family),
    plot.title = element_text(hjust = 0.5, size = fontsize_large, margin = margin(t = 0, r = 0, b = 0, l = 0), ),
    plot.subtitle = element_text(hjust = 0.5, size = fontsize_small, margin = margin(t = 5, r = 5, b = 10, l = 10)),
    # legend
    legend.text = element_text(size = fontsize_small),
    legend.position = "right",                     # legend position on the top of the graph
    legend.key.height = unit(2, "cm"),          # size of legend keys, tacche legenda
    legend.key.width = unit(0.4, "cm"),
    legend.direction = "vertical",             # layout of items in legends
    legend.box = "vertical",                   # arrangement of multiple legends
    legend.title = element_blank(),      # title of legend (inherits from title)
    # strip.text = element_text(size = 17), # facet wrap title fontsize
    # AXIS X
    #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.x = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), 
                               angle = 0),
    # AXIS Y
    #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.y = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), 
                               angle = 0),
    # background
    panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
    panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
    panel.grid.minor = element_blank(),            # draws nothing, and assigns no space.
    plot.margin = unit(c(plot_margin,plot_margin,plot_margin,plot_margin), "cm")
  )         # margin around entire plot

ggsave(filename = file.path("Polito_Usecase", "figures","ctx_from05_15_to06_15_m02_30","Cluster_2", "cmp_context_R.png"), width = 6, height = 5.5, dpi = dpi )

dev.off()

