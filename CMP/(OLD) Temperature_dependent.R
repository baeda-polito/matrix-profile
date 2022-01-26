# #  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
# cat("\014")                 # clears the console
# rm(list = ls())             # remove all variables of the workspace
# source("global_vars.R")
# source("utils_functions.R")
# 
# library(magrittr)
# library(dplyr)
# library(ggplot2)
# library(scales)
# 
# 
# # DATASET PRE-PROCESSING: ------------------------------------
# #   - Load all dataset "df_cabinaC_2019_labeled.csv"
# #   - Load all dataset "group_cluster.csv" and see dates to exclude
# #   - Fix datetime and variables
# #   - Remove holidays and working days
# #   - Keep only interesting variables
# 
# df_time_window <- read.csv(
#   file = file.path("Polito_Usecase", "data", "time_window.csv"),
#   sep = ',',
#   dec = ".",
#   stringsAsFactors = TRUE
# ) %>%
#   mutate(from = hour_to_dec(as.character(from)),
#     to = hour_to_dec(as.character(to))) %>%
#   select(id, from, to)
# 
# 
# df_cluster <- read.csv(
#   file = file.path("Polito_Usecase", "data", "group_cluster.csv"),
#   sep = ',',
#   dec = ".",
#   stringsAsFactors = TRUE
# ) %>%
#   mutate(cluster = as.factor(ifelse(
#     Cluster_1 == TRUE,
#     "Cluster_1",
#     ifelse(
#       Cluster_2 == TRUE,
#       "Cluster_2",
#       ifelse(
#         Cluster_3 == TRUE,
#         "Cluster_3",
#         ifelse(Cluster_4 == TRUE, "Cluster_4",
#           "Cluster_5")
#       )
#     )
#   )),
#     Date = timestamp) %>%
#   select(Date, cluster)
# 
# # per cluster
# # per contesto facet
# 
# 
# df <- read.csv(
#   file = file.path("Polito_Usecase", "data", "df_cabinaC_2019_labeled.csv"),
#   sep = ',',
#   dec = ".",
#   stringsAsFactors = TRUE
# ) %>%
#   mutate(
#     Date_Time = as.POSIXct(Date_Time, format = "%Y-%m-%d %H:%M:%S" , tz = "GMT") ,
#     min_dec = hour_to_dec(format(Date_Time, "%H:%M")),
#     time_window = as.factor(
#       ifelse(
#         min_dec >= df_time_window$from[1] & min_dec < df_time_window$to[1],
#         paste("Time window",df_time_window$id[1]),
#         ifelse(
#           min_dec >= df_time_window$from[2] & min_dec < df_time_window$to[2],
#           paste("Time window",df_time_window$id[2]),
#           ifelse(
#             min_dec >= df_time_window$from[3] & min_dec < df_time_window$to[3],
#             paste("Time window",df_time_window$id[3]),
#             ifelse(
#               min_dec >= df_time_window$from[4] & min_dec < df_time_window$to[4],
#               paste("Time window",df_time_window$id[4]),
#               paste("Time window",df_time_window$id[5])
#             )
#           )
#         )
#       )
#     )
#   ) %>%
#   select(Date_Time, time_window, Date, Total_Power, AirTemp)
# 
# df_joint <- merge.data.frame(df, df_cluster) %>% 
#   group_by(Date, cluster, time_window) %>% 
#   summarise(
#     E_tot = sum(Total_Power),
#     T_mean = mean(AirTemp)
#   )
# 
# 
# df_joint %>%
#   ggplot() +
#   geom_point(aes(x = T_mean, y = E_tot, color = cluster), show.legend = F) +
#   facet_grid(time_window ~ cluster)
# 
# 
# # df <-  read.csv(file.path(getwd(),"Polito_Usecase", "data",  "polito_raw.csv"), sep = ',', dec = ".") %>%
# #   mutate(timestamp = as.POSIXct(Date_Time, "%Y-%m-%d %H:%M:%S", tz = "GMT"), # occhio al cambio ora
# #     value = Total_Power,
# #     Date = as.Date(timestamp),
# #     time_dec = hour_to_dec(Time),
# #     Time = as.ordered(Time)
# #   ) %>%
# #   filter( !(Date %in% df_cluster$Date) ) %>%
# #   select(timestamp, Date, time_dec, value, Time)
# #
# # ###### CART for time windows definition:
# # #   - Target Variable: value (Total Power kWh)
# # #   - Predictive Variable: time_dec (Hour decimal form h)
# # #   - cp = 0 (no limits to complexity)
# # #   - xval = 100 (cross validation to 100 folds)
# # #   - maxdepth = 10 (maximum 10 splits)
# # #   - minbucket = 60[min/h]*2.5[h]/15[min]*n[days] (minimum 2h in leaf nodes)
# #
# # ct <- rpart::rpart(value ~ time_dec,
# #   data = df,
# #   control = rpart::rpart.control(
# #     minbucket = 60*2.5/15*length(unique(df$Date)),  # 120 min 15 minutes sampling*number of days
# #     cp = 0 ,
# #     xval = 100,
# #     maxdepth = 10)
# # )
# #
# # # Print complexity parameter
# # dev.new()
# # png(file = file.path("Polito_Usecase", "figures", "time_window_cp.jpg"),
# #   bg = "white", width = 2000, height = 1300, res = dpi)
# # plotcp(ct, lty = 2, col = "red", upper = "size", family = font_family)
# # dev.off()
# #
# # # Print tree
# # dev.new()
# # png(
# #   file = file.path("Polito_Usecase", "figures", "time_window_cart.jpg"),
# #   bg = "white",
# #   units = "in",
# #   width = 8,
# #   height = 5,
# #   res = dpi
# # )
# # ct1 <- as.party(ct)
# # names(ct1$data) <- c("Total Power", "Hour") # change labels to plot
# # plot(
# #   ct1,
# #   tnex = 2.8,
# #   terminal_panel = node_boxplot,
# #   tp_args = list(bg = "white", cex = 0.2, fill = "gray"),
# #   inner_panel = node_inner,
# #   ip_args = list(),
# #   edge_panel = edge_simple,
# #   ep_args = list(fill = "white"),
# #   gp = gpar(fontsize = fontsize_small - 1,  fontfamily = font_family)
# # )
# # dev.off()
# #
# #
# #
# # # the tree defines the length of time windows and the region of interest
# # # all subsequences should end in this interest region
# # window_limit <- ct$splits[,4]                       # get splits from tree
# # window_limit <- c(0,window_limit,24)                # adds 0 e 24
# # names(window_limit) <- NULL                         # removes names
# # window_limit <- sort(window_limit)                  # reorder
# #
# #
# # hour <- trunc(window_limit)                         # gets hour from tw
# # minutes <- ceiling((window_limit-hour)*60)          # gets minutes from tw
# # corresponding_quarter <- floor(minutes/15)          # round to nearest 15 min
# # minutes_corrected <- 15*corresponding_quarter       # corrects minutes
# #
# # # set limits to tw
# # time <- hm(paste(hour, minutes_corrected))          # transforms to hour
# # time_posixct <- as.POSIXct(time,  origin = "1970-01-01", tz = "GMT")
# # time_posixct_string <- format(sort(time_posixct), "%H:%M")
# # time_posixct_string[length(time_posixct_string)] <- "24:00"
# # names(time_posixct_string) <- NULL
# #
# #
# # # initialize dataframe
# # time_window_df <- data.frame(
# #   id = seq(0, 0, length.out = length(time_posixct_string)-1),
# #   description = seq(0, 0, length.out = length(time_posixct_string)-1),
# #   observations = seq(0, 0, length.out = length(time_posixct_string)-1),
# #   from = seq(0, 0, length.out = length(time_posixct_string)-1),
# #   to = seq(0, 0, length.out = length(time_posixct_string)-1),
# #   duration = seq(0, 0, length.out = length(time_posixct_string)-1),
# #   node = seq(0, 0, length.out = length(time_posixct_string)-1)
# # )
# #
# #
# # nodes <- c("Node 2","Node 6","Node 9","Node 8","Node 4")
# # # add columns to dataframe
# # for (i in 1: (length(time_posixct_string)-1)) {
# #   time_window_df$id[i] <- i
# #   time_window_df$description[i] <- paste("From", time_posixct_string[i], "to", time_posixct_string[i+1])
# #   time_window_df$from[i] <- time_posixct_string[i]
# #   time_window_df$to[i] <- time_posixct_string[i+1]
# #   time_window_df$observations[i] <- (as.duration(time)[i+1]-as.duration(time)[i])/duration(minutes=15)
# #   time_window_df$duration[i] <- paste(as.duration(time[i+1]-time[i]))
# #   time_window_df$node[i] <- nodes[i]
# # }
# #
# # time_window_df
# #
# # # save for further analysis
# # write.csv(time_window_df, file.path("Polito_Usecase", "data", "time_window.csv"), row.names = FALSE)
# #
# #
# # ###### CONTEXT :
# # # we can define the length of the context in two ways
# # # - supervised: set to 1
# # # - get the smallest time window and divide in two
# #
# # m_context <- floor(min(time_window_df$observations)/4/2)
# # m_context <- 1 # [hour]
# #
# # # save context length
# # write.csv(data.frame(m_context = m_context), file = file.path("Polito_Usecase", "data", "m_context.csv"), row.names = FALSE)
# #
# #
# #
# # ###### PLOTS
# # # we can define the length of the context in two ways
# # # number of time windows
# #
# # time_windows_n <- dim(time_window_df)[1]
# # # define colors for time windows
# # time_windows_palette <- RColorBrewer::brewer.pal(time_windows_n, "Dark2")
# #
# #
# # # I want to plot the time windows on the dataset
# # dev.new()
# # ggplot() +
# #   annotate(
# #     "rect",
# #     xmin = as.POSIXct( paste(time_window_df$from, ":00", sep = ""), format = "%H:%M" , tz = "GMT"),
# #     xmax = as.POSIXct( paste(time_window_df$to, ":00", sep = ""), format = "%H:%M" , tz = "GMT"),
# #     ymin = -Inf,
# #     ymax = Inf,
# #     alpha = 0.1,
# #     color = "black",
# #     lty = 3,
# #     lwd = 0.1,
# #     fill = time_windows_palette
# #   ) +
# #   annotate("text",
# #     size = 3,
# #     x = as.POSIXct( paste(time_window_df$from, ":00", sep = ""), format = "%H:%M" , tz = "GMT")+
# #       lubridate::hours(c(3,1,3,1,2)) + lubridate::minutes(c(0,20,15,40,30)) ,
# #     y = c(850,850,850,850,850),
# #     label = time_window_df$node
# #   )+
# #   geom_line(
# #     data = df,
# #     aes(
# #       x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") ,
# #       y = value,
# #       group = Date
# #     ) ,
# #     color = "black",
# #     alpha = 0.1,
# #     size = 0.3
# #   ) +
# #   scale_x_datetime(
# #     expand = c(0, 0),
# #     labels = date_format("%H:%M" , tz = "GMT"),
# #     breaks = as.POSIXct(paste(
# #       c(time_window_df$from, "23:59"), ":00", sep = ""), format = "%H:%M:%S" , tz = "GMT")
# #   ) +
# #   scale_y_continuous(limits = c(0, ceiling(max(df$value) / 100) * 100), expand = c(0, 0)) +
# #   theme_minimal() +
# #   ggplot2::theme(
# #     text = element_text(family = font_family),
# #     axis.ticks = element_line(colour = "black"),
# #     panel.grid = element_blank(),
# #     axis.line.y = element_line(colour = "black"),
# #     axis.line.x = element_line(colour = "black"),
# #
# #     plot.title = element_text(hjust = 0.5, size = fontsize_large, margin = margin(t = 0, r = 0, b = 0, l = 0), ),
# #     plot.subtitle = element_text(hjust = 0.5, size = fontsize_small, margin = margin(t = 5, r = 5, b = 10, l = 10)),
# #     # legend
# #     legend.position = "none",                     # legend position on the top of the graph
# #     # strip.text = element_text(size = 17), # facet wrap title fontsize
# #     # AXIS X
# #     #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
# #     axis.text.x = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), angle = 0, vjust=.3),
# #     # AXIS Y
# #     #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
# #     axis.text.y = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 0, l = 5), angle = 0, vjust=.3),
# #     # background
# #     # panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
# #     #panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
# #     panel.grid.minor = element_blank(),            # draws nothing, and assigns no space.
# #     plot.margin = unit(c(plot_margin,plot_margin,plot_margin,plot_margin), "cm")
# #   ) +
# #   labs(x = NULL , y = "Power [kW]")
# #
# #
# # ggsave(filename = file.path("Polito_Usecase", "figures", "time_window_profiles.jpg"),
# #   width = 6, height = 4, dpi = dpi,  bg = background_fill)
# #
# # dev.off()
# #
# #
