#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
library(magrittr)
library(dplyr)
library(lubridate)
library(rpart)
library(partykit)

#### togli festivi
# df <-  read.csv('/Users/robi/Desktop/matrix_profile/Simone Deho/df_cabinaC_2019_labeled.csv', sep = ',') %>%
#   dplyr::mutate(timestamp = as.POSIXct(Date_Time, "%Y-%m-%d %H:%M:%S", tz = "GMT"), # occhio al cambio ora
#                 value = Total_Power,
#                 Date = as.Date(timestamp),
#                 time_dec = paste( hour(Date_Time), minute(Date_Time)*100/60, sep = "."),
#                 time_dec = as.numeric(time_dec)
#   ) %>%
#   dplyr::filter(Day_Type != 6 & Day_Type != 7) %>%
#   dplyr::select(timestamp, Date, time_dec, value)


# try to define daily context in unsupervided way through CART
df <- read.csv(file.path("Polito_Usecase", "data", "polito.csv"), sep = ',') %>%
  dplyr::mutate(timestamp = as.POSIXct(timestamp, "%Y-%m-%d %H:%M:%S", tz = "GMT"), # occhio al cambio ora
                Date = as.Date(timestamp),
                time_dec = paste( hour(timestamp), minute(timestamp)*100/60, sep = "."),
                time_dec = as.numeric(time_dec)
  )


ct <- rpart::rpart(value ~ time_dec,                                                    # target attribute based on training attributes
                   data = df,                                                               # data to be used
                   control = rpart::rpart.control(minbucket = 60*2.5/15*length(unique(df$Date)),  # 120 min 15 minutes sampling*number of days
                                                  cp = 0 ,                                          # nessun vincolo sul cp permette lo svoluppo completo dell'albero
                                                  # xval = (length(df) - 1 ),                        # !!!!!!! ATTENZIONE non dovrebbe essere dim()[1] ?? k-fold leave one out LOOCV dim
                                                  xval = 100,                        # !!!!!!! ATTENZIONE non dovrebbe essere dim()[1] ?? k-fold leave one out LOOCV dim
                                                  maxdepth = 10)) 

# minsplit:     Set the minimum number of observations in the node before the algorithm perform a split
# minbucket:    Set the minimum number of observations in the final note i.e. the leaf
# maxdepth:     Set the maximum depth of any node of the final tree. The root node is treated a depth 0


# stampa complexity parameter
dev.new()
png(file = file.path("Polito_Usecase", "figures", "cart_contexts_cp.png"), 
    bg = "white", width = 500, height = 300)    
plotcp(ct, lty = 2, col = "red", upper = "size", family = font_family)
dev.off()

# stampa albero
dev.new() 


png(file = file.path("Polito_Usecase", "figures", "cart_contexts.png"), bg = "white", width = 700, height = 400)  
ct1 <- partykit::as.party(ct)
names(ct1$data) <- c("Total Power", "Hour") # change labels to plot

plot(ct1, tnex = 2.5,  
     terminal_panel = node_boxplot,
     tp_args = list(bg = "white", cex = 0.2, fill = "gray"),
     inner_panel = node_inner, 
     ip_args = list(),
     edge_panel = edge_simple,
     ep_args = list(fill = "white"),
     gp = gpar(fontsize = fontsize_medium,  fontfamily = font_family))
dev.off()


context_limits <- ct$splits[,4]                 # prende dall'albero gli split
context_limits <- context_limits[order(context_limits)]    # ordina gli split
context_limits <- c(0,context_limits,24)        # aggiunge 0 e 24
names(context_limits) <- NULL                   # removes names from context
context_limits <- sort(context_limits)          # limits of context decimal


hour <- trunc(context_limits)
minutes <- ceiling((context_limits-hour)*60)

# round to nearest 15 min
corresponding_quarter <- floor(minutes/15)
minutes_corrected <- 15*corresponding_quarter

time <- hm(paste(hour, minutes_corrected))
time_posixct <- as.POSIXct(time,  origin = "1970-01-01", tz = "GMT")
time_posixct_string <- format(sort(time_posixct), "%H:%M")
time_posixct_string[length(time_posixct_string)] <- "24:00"
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
