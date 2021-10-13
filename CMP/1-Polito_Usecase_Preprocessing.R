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

# reads the complete dataframe
df <- read.csv(file.path(dirname(dirname(getwd())), "Simone Deho", "df_cabinaC_2019_labeled.csv"), sep = ',') 

tt <- df %>%
  select(Date, Holiday, Day_Description) %>%
  unique()

df_py <- df %>%
  mutate(
    timestamp = Date_Time,
    value = Total_Power
  ) %>%
  dplyr::select(timestamp, value)

summary(df_py)

# convert into python readable dataframe
write.csv(df_py, file = file.path("Polito_Usecase", "data", "polito.csv"), row.names = FALSE)


dev.new() 
df %>%
  mutate(Date = as.Date(Date)) %>%
  ggplot() + # crea lo sfondo del grafico
  geom_tile(aes(x = as.POSIXct(Time, format = "%H:%M:%S", tz = "Etc/GMT+12") , y = Date , fill = Total_Power)) +
  # tile crea un grafico a tre dimensioni x y z = fill con il data set df_tot
  # aes creates an aestetic property to data
  # as.POSIXct converte le ore a formato standard
  scale_fill_gradientn(
    colours = palette,
    na.value = "white",
    limits = c(0, 800), 
    breaks = round(seq(0,800, by = 150)),
    labels = paste(round(seq(0,800, by = 150)),"kW")
  )+
  scale_y_date(
    breaks = date_breaks("1 month"),                    # specify breaks every two months
    labels = date_format("%b" , tz = "Etc/GMT+12"),  # specify format of labels anno mese
    expand = c(0,0)                                     # espande l'asse y affinche riempia tutto il box in verticale
  ) +
  scale_x_datetime(
    breaks = date_breaks("3 hour"),                     # specify breaks every 4 hours
    labels = date_format(("%H:%M") , tz = "Etc/GMT+12"),# specify format of labels ora minuti
    expand = c(0,0)                                     # espande l'asse x affinche riempia tutto il box in orizzontale
  ) +
  coord_flip()+
  theme_bw() + # white bakground with lines
  
  ggplot2::theme(
    text = element_text(family = font_family),
    plot.title = element_text(hjust = 0.5, size = fontsize_large, margin = margin(t = 0, r = 0, b = 0, l = 0), ),
    plot.subtitle = element_text(hjust = 0.5, size = fontsize_small, margin = margin(t = 5, r = 5, b = 10, l = 10)),
    # legend
    legend.text = element_text(size = fontsize_small),
    legend.position = "top",                     # legend position on the top of the graph
    legend.key.height = unit(0.4, "cm"),          # size of legend keys, tacche legenda
    legend.key.width = unit(2.5, "cm"),
    legend.direction = "horizontal",             # layout of items in legends
    legend.box = "horizontal",                   # arrangement of multiple legends
    legend.title = element_text(vjust = 0.85),      # title of legend (inherits from title)
    # AXIS X
    #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.x = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), 
                               angle = 0, vjust=.3, hjust = 0.5),
    # AXIS Y
    #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.y = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), 
                               angle = 0, vjust=0.5),
    panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
    panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
    panel.grid.minor = element_blank(),            # draws nothing, and assigns no space.
    plot.margin = unit(c(plot_margin,plot_margin,plot_margin,plot_margin), "cm")
  ) +
  labs(x = "", y = "", fill = "")

ggsave(filename = file.path("Polito_Usecase", "figures", "dataset_carpet,jpg"), width = 7, height = 4, dpi = dpi )

dev.off()







# 
# as.integer(as.factor(df$Holiday))
# # holiday annotation
# df_py_holiday <- df %>%
#   mutate(
#     timestamp = as.Date(Date_Time),
#     week_day = lubridate::wday(timestamp, week_start = getOption("lubridate.week.start", 1)),
#     holiday_bool = as.logical( as.integer(as.factor(df$Holiday))-1 ),
#     #holiday_bool = ifelse( timestamp %in% as.Date(hol), TRUE, holiday_bool), # add not counted holidays
#     saturday_bool = if_else( !holiday_bool & week_day == 6, TRUE, FALSE),
#     workingday_bool = if_else( !holiday_bool & week_day != 6 & week_day != 7, TRUE, FALSE),
#   ) %>%
#   dplyr::select(timestamp, holiday_bool, saturday_bool, workingday_bool) %>%
#   unique()
# 
# 
# colnames(df_py_holiday)[2] <- "Holiday"
# colnames(df_py_holiday)[3] <- "Saturday"
# colnames(df_py_holiday)[4] <- "Working Day"
# # 
# # # create a fill dataframe
# # start <- df_py_holiday$timestamp[1]
# # interval <- 60*24
# # 
# # end <- start + as.difftime(151, units="days")
# # 
# # ttt <- data.frame(timestamp = seq(from=start, by=1, to=end))
# # 
# # df_py_holiday <- merge.data.frame(ttt, df_py_holiday, all.x =  T)
# # df_py_holiday <- df_py_holiday[1:151,]
# 
# 
# write.csv(df_py_holiday, file = file.path("Polito_Usecase", "data", "polito_holiday.csv"), row.names = FALSE)
# 



