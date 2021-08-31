#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
library(magrittr)
library(dplyr)
library(lubridate)
library(rpart)
library(partykit)
library(ggplot2)
library(scales)

### All dataset removing holidays and weekends
df <-  read.csv('/Users/robi/Desktop/matrix_profile/Simone Deho/df_cabinaC_2019_labeled.csv', sep = ',') %>%
  dplyr::mutate(timestamp = as.POSIXct(Date_Time, "%Y-%m-%d %H:%M:%S", tz = "GMT"), # occhio al cambio ora
                value = Total_Power,
                Date = as.Date(timestamp),
                time_dec = paste( hour(Date_Time), minute(Date_Time)*100/60, sep = "."),
                time_dec = as.numeric(time_dec)
  ) %>%
  dplyr::filter(Holiday != "Yes" & Day_Type != 6 & Day_Type != 7) %>%
  dplyr::select(timestamp, Date, time_dec, value, Time)

# do a cart with electrical load and hour as decimal
ct <- rpart::rpart(value ~ time_dec,     # target attribute based on training attributes
                   data = df,            # data to be used
                   control = rpart::rpart.control(minbucket = 60*2.5/15*length(unique(df$Date)),  # 120 min 15 minutes sampling*number of days
                                                  cp = 0 ,                                        # nessun vincolo sul cp permette lo svoluppo completo dell'albero
                                                  # xval = (length(df) - 1 ),                     # !!!!!!! ATTENZIONE non dovrebbe essere dim()[1] ?? k-fold leave one out LOOCV dim
                                                  xval = 100,                        
                                                  maxdepth = 10)) 

# minsplit:     Set the minimum number of observations in the node before the algorithm perform a split
# minbucket:    Set the minimum number of observations in the final note i.e. the leaf
# maxdepth:     Set the maximum depth of any node of the final tree. The root node is treated a depth 0

# stampa complexity parameter
dev.new()
png(file = file.path("Polito_Usecase", "figures", "time_window_cp.png"), 
    bg = "white", width = 2000, height = 1300, res = dpi) 
plotcp(ct, lty = 2, col = "red", upper = "size", family = font_family)
dev.off()

# stampa albero
dev.new() 
png(file = file.path("Polito_Usecase", "figures", "time_window_cart.png"), bg = "white", width = 2000, height = 1300, res = dpi) 
ct1 <- partykit::as.party(ct)
names(ct1$data) <- c("Total Power", "Hour") # change labels to plot
plot(ct1, tnex = 2.8,  
     terminal_panel = node_boxplot,
     tp_args = list(bg = "white", cex = 0.2, fill = "gray"),
     inner_panel = node_inner, 
     ip_args = list(),
     edge_panel = edge_simple,
     ep_args = list(fill = "white"),
     gp = gpar(fontsize = fontsize_small-1,  fontfamily = font_family))
dev.off()

# the tree defines the length of time windows and the region of interest
# all subsequences should end in this interest region
window_limit <- ct$splits[,4]                 # prende dall'albero gli split
window_limit <- window_limit[order(window_limit)]    # ordina gli split
window_limit <- c(0,window_limit,24)        # aggiunge 0 e 24
names(window_limit) <- NULL                   # removes names from context
window_limit <- sort(window_limit)          # limits of context decimal


hour <- trunc(window_limit)
minutes <- ceiling((window_limit-hour)*60)

# round to nearest 15 min
corresponding_quarter <- floor(minutes/15)
minutes_corrected <- 15*corresponding_quarter

time <- hm(paste(hour, minutes_corrected))
time_posixct <- as.POSIXct(time,  origin = "1970-01-01", tz = "GMT")
time_posixct_string <- format(sort(time_posixct), "%H:%M")
time_posixct_string[length(time_posixct_string)] <- "23:45"
names(time_posixct_string) <- NULL

time_window_df <- data.frame(
  description = seq(0, 0, length.out = length(time_posixct_string)-1), 
  observations = seq(0, 0, length.out = length(time_posixct_string)-1),
  from = seq(0, 0, length.out = length(time_posixct_string)-1),
  to = seq(0, 0, length.out = length(time_posixct_string)-1)
)

for (i in 1: (length(time_posixct_string)-1)) {
  time_window_df$description[i] <- paste("From", time_posixct_string[i], "to", time_posixct_string[i+1])
  time_window_df$from[i] <- time_posixct_string[i]
  time_window_df$to[i] <- time_posixct_string[i+1]
  time_window_df$observations[i] <- (as.duration(time)[i+1]-as.duration(time)[i])/duration(minutes=15)
}

time_window_df

write.csv(time_window_df, file.path("Polito_Usecase", "data", "time_window.csv"))



# number of time windows
time_windows_n <- dim(time_window_df)[1]
# define colors for time windows
time_windows_palette <- RColorBrewer::brewer.pal(time_windows_n, "Set1")




# I want to plot the time windows on the dataset
dev.new()
ggplot() +
  annotate(
    "rect",
    xmin = as.POSIXct( paste(time_window_df$from, ":00", sep = ""), format = "%H:%M:%S" , tz = "GMT"),
    xmax = as.POSIXct( paste(time_window_df$to, ":00", sep = ""), format = "%H:%M:%S" , tz = "GMT"),
    ymin = -Inf,
    ymax = Inf,
    alpha = 0.2,
    color = "black",
    lty = 3,
    lwd = 0.1,
    fill = time_windows_palette
  ) + 
  geom_line(data = df, 
            aes(x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") , y = value, group = Date) , 
            color = "black", alpha = 0.1, size = 0.4) + 
  scale_x_datetime(expand = c(0,0), 
                   labels = date_format("%H:%M" , tz = "GMT"), 
                   breaks = as.POSIXct( paste( c(time_window_df$from, "23:45"), ":00", sep = ""), format = "%H:%M:%S" , tz = "GMT") ) +
  scale_y_continuous(limits = c(0,ceiling(max(df$value)/100)*100), expand = c(0,0)) +
  theme_bw() +
  labs(title = "Interesting zone",
       subtitle = "Unsupervised Identification where subsequence ends",
       x = "" , y = "Power [kW]")+
  ggplot2::theme(
    text=element_text(family=font_family),
    plot.title = element_text(hjust = 0.5, size = fontsize_large, margin = margin(t = 0, r = 0, b = 0, l = 0), ),
    plot.subtitle = element_text(hjust = 0.5, size = fontsize_small, margin = margin(t = 5, r = 5, b = 10, l = 10)),
    # legend
    legend.position = "none",                     # legend position on the top of the graph
    # strip.text = element_text(size = 17), # facet wrap title fontsize
    # AXIS X
    #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.x = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), angle = 0, vjust=.3),
    # AXIS Y
    #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.y = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), angle = 0, vjust=.3),
    # background
    panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
    panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
    panel.grid.minor = element_blank(),            # draws nothing, and assigns no space.
    plot.margin = unit(c(plot_margin,plot_margin,plot_margin,plot_margin), "cm")
  )         # margin around entire plot


ggsave(filename = file.path("Polito_Usecase", "figures", "time_window_definition.png"), width = 7, height = 4.5, dpi = 200 )

dev.off()






