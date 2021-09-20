#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")

library(ggplot2)
library(dplyr)
library(magrittr)
library(tidyr)
library(scales)
library(tidyverse)


########### carpet heatmap
df <-  read.csv(file.path(dirname(dirname(getwd())), "Simone Deho", "df_cabinaC_2019_labeled.csv"), sep = ',')


###########
df <-  read.csv(file.path("Polito_Usecase", "data", "ctx_from04_00_to06_00_m02_30", "plot_cmp_full.csv"), sep = ',', header = F)

colnames(df) <- as.Date(read.csv(file.path("Polito_Usecase", "data", "polito_holiday.csv"), sep = ',', header = T)[,1])
rownames(df) <- as.Date(read.csv(file.path("Polito_Usecase", "data", "polito_holiday.csv"), sep = ',', header = T)[,1])

df_long <- df %>% 
  rownames_to_column("Date") %>%
  pivot_longer(-c(Date), names_to = "Date1", values_to = "values") %>%
  mutate(Date = as.Date(Date),
         Date1 = as.Date(Date1),
  )

# spot the maximum ant the minimum

maximum_value <- round(maximum_value, digits = -2)


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

ggsave(filename = file.path("Polito_Usecase", "figures","ctx_from04_00_to06_00_m02_30", "cmp_context_R.png"), width = 6, height = 5.5, dpi = dpi )

dev.off()


