#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
source("utils_functions.R")

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(tidyverse)
library(ggpubr)
import::from(magrittr, "%>%")






###### RESULT POST PROCESSING

# SECTION ------------------------------------

df_results <-  read.csv(file.path("Polito_Usecase", "data", "anomaly_results.csv"))

# SECTION ------------------------------------
df_corrected <- df_results %>%
  select(-c(Cluster_1,Cluster_2,Cluster_3,Cluster_4, Cluster_5)) %>%
  pivot_longer(cols=c(-timestamp), names_to = "context", values_to = "severity") %>% 
  mutate(
    cluster = ifelse(grepl("Cluster_1.", context),
      "Cluster 1", 
      ifelse(grepl("Cluster_2.", context),
        "Cluster 2",
        ifelse(grepl("Cluster_3.", context),
          "Cluster 3", ifelse(grepl("Cluster_4.", context),
            "Cluster 4", "Cluster 5")))),
    cluster = as.factor(cluster),
    context = gsub("Cluster_1.","",context),
    context = gsub("Cluster_2.","",context),
    context = gsub("Cluster_3.","",context),
    context = gsub("Cluster_4.","",context),
    context = gsub("Cluster_5.","",context),
    context = as.factor(as.numeric(as.factor(context))),
    severity = as.factor(severity)
  ) %>% 
  mutate(context = paste("Context",context),
    severity = as.numeric(severity)) %>%
  rename(Date = timestamp)


# gets the top anomalies fro plot
df_dates <- data.frame()

for (cluster_index in c(1:5)) {
  
  for (context_index in c(1:5)) {
    
    df_corrected2 <- df_corrected %>%
      filter(
        cluster == paste0("Cluster ", cluster_index),
        context == paste0("Context ", context_index)) %>%
      arrange(desc(severity))
    
    df_dates <- rbind(df_dates, df_corrected2[1,])
  }
  
  
}

# SECTION ------------------------------------

# load power data full
df_power <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data",  "polito_raw.csv"),
    sep = ',',
    dec = "."
  ) %>%
  dplyr::select(Date, Time, Total_Power)

# SECTION ------------------------------------

# add cluster info
df_cluster <-
  read.csv(
    file.path(getwd(), "Polito_Usecase", "data",  "group_cluster.csv"),
    sep = ',',
    dec = "."
  ) %>%
  rename(Date = timestamp)

for (i in 1:dim(df_cluster)[1]) {
  df_cluster$cluster[i] <-   colnames(df_cluster)[which(df_cluster[i,] == TRUE)]
}

df_cluster <- df_cluster %>% 
  mutate(cluster = gsub("_", " ", cluster)) %>% 
  select(Date,cluster)

df_merged <- merge.data.frame(df_power, df_cluster, by = "Date")

# SECTION ------------------------------------
df_time_window <- read.csv(
  file = file.path("Polito_Usecase", "data", "time_window.csv"),
  sep = ',',
  dec = ".",
  stringsAsFactors = TRUE
) %>%
  mutate(from = hour_to_dec(as.character(from)),
    to = hour_to_dec(as.character(to))) %>%
  select(id, from, to)

df_merged1 <- df_merged%>%
  mutate(
    Date_Time = as.POSIXct(paste(Date,Time), format = "%Y-%m-%d %H:%M:%S" , tz = "GMT") ,
    min_dec = hour_to_dec(format(Date_Time, "%H:%M")),
    time_window = as.factor(
      ifelse(
        min_dec >= df_time_window$from[1] & min_dec < df_time_window$to[1],
        paste("Time window",df_time_window$id[1]),
        ifelse(
          min_dec >= df_time_window$from[2]-1 & min_dec < df_time_window$to[2],
          paste("Time window",df_time_window$id[2]),
          ifelse(
            min_dec >= df_time_window$from[3]-1 & min_dec < df_time_window$to[3],
            paste("Time window",df_time_window$id[3]),
            ifelse(
              min_dec >= df_time_window$from[4]-1 & min_dec < df_time_window$to[4],
              paste("Time window",df_time_window$id[4]),
              paste("Time window",df_time_window$id[5])
            )
          )
        )
      )
    )
  ) %>% 
  select(Date,Time,cluster, time_window,Total_Power) %>% 
  mutate(
    anomaly = ifelse(Date %in% df_dates$Date, 1,0),
    severity = ifelse(Date %in% df_dates$Date, df_dates$severity,0),
    combination = paste(cluster,time_window)
  )


dates_list <- list(
  "Context 1" = list(
    "Cluster 1" = "2019-07-14",
    "Cluster 2" = "2019-07-27",
    "Cluster 3" = "2019-08-07",
    "Cluster 4" = "2019-07-16",
    "Cluster 5" = "2019-06-05"
  ),
  "Context 2" = list(
    "Cluster 1" = "2019-07-14",
    "Cluster 2" = "2019-07-27",
    "Cluster 3" = "2019-08-07",
    "Cluster 4" = "2019-07-16",
    "Cluster 5" = "2019-06-05"
  ),
  "Context 3" = list(
    "Cluster 1" = "2019-07-14",
    "Cluster 2" = "2019-07-27",
    "Cluster 3" = "2019-08-07",
    "Cluster 4" = "2019-07-16",
    "Cluster 5" = "2019-06-05"
  ),
  "Context 4" = list(
    "Cluster 1" = "2019-07-14",
    "Cluster 2" = "2019-07-27",
    "Cluster 3" = "2019-08-07",
    "Cluster 4" = "2019-07-16",
    "Cluster 5" = "2019-06-05"
  ),
  "Context 5" = list(
    "Cluster 1" = "2019-07-14",
    "Cluster 2" = "2019-07-27",
    "Cluster 3" = "2019-08-07",
    "Cluster 4" = "2019-07-16",
    "Cluster 5" = "2019-06-05"
  )
)

for (cluster_index in c(1:5)) {
  
  for (tw_index in c(1:5)) {
  
    
    date <- dates_list[[paste("Context",tw_index)]][[paste("Cluster",cluster_index)]]
    
    
    dev.new()
    p1 <- ggplot() +
      geom_line(
        data = df_merged1 %>% filter(cluster == paste("Cluster",cluster_index) ),
        aes(
          x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") ,
          y = Total_Power,
          group = Date
        ) ,
        color = "#D5D5E0",
        #alpha = 0.3,
        size = 0.7
      ) +
      geom_line(
        data = df_merged1 %>% filter(Date == date),
        aes(
          x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") ,
          y = Total_Power,
          group = Date
        ) ,
        color = "red",
        #alpha = 0.3,
        size = 0.7
      ) +
      scale_x_datetime(
        expand = c(0, 0),
        labels = date_format("%H:%M" , tz = "GMT"),
        breaks = date_breaks("4 hour")
      ) +
      scale_y_continuous(limits = c(0,900),
        expand = c(0, 0)) +
      theme_bw() +
      labs(
        title = paste("Cluster",cluster_index, "Time window", tw_index),
        subtitle = format(as.Date(date), "%d-%m-%Y"),
        x = "Hour" ,
        y = "Power [kW]") +
      theme_minimal() +
      ggplot2::theme(
        text = element_text(family = font_family),
        axis.ticks = element_line(colour = "black"),
        panel.grid = element_blank(),
        axis.line.y = element_line(colour = "black"),
        axis.line.x = element_line(colour = "black"),
        plot.title = element_text(
          hjust = 0.5,
          size = fontsize_large,
          margin = margin(
            t = 0,
            r = 0,
            b = 0,
            l = 0
          )
        ),
        plot.subtitle = element_text(
          hjust = 0.5,
          size = fontsize_small,
          margin = margin(
            t = 5,
            r = 5,
            b = 10,
            l = 10
          )
        ),
        # legend
        legend.position = "none",
        # legend position on the top of the graph
        # strip.text = element_text(size = 17), # facet wrap title fontsize
        # AXIS X
        #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
        axis.text.x = element_text(
          size = fontsize_small,
          margin = margin(
            t = 5,
            r = 5,
            b = 5,
            l = 5
          ),
          angle = 45,
          vjust = .3
        ),
        # AXIS Y
        #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
        axis.text.y = element_text(
          size = fontsize_small,
          margin = margin(
            t = 5,
            r = 5,
            b = 0,
            l = 5
          ),
          angle = 0,
          vjust = .3
        ),
        # background
        # panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
        #panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
        panel.grid.minor = element_blank(),
        # draws nothing, and assigns no space.
        plot.margin = unit(c(
          plot_margin, plot_margin, plot_margin, plot_margin
        ), "cm")
      )
    
    
    p1
    
    
    ggsave(filename = file.path("Polito_Usecase", "figures", "results_profiles", paste0("Cluster ",cluster_index, "Time window ", tw_index, ".jpg")), 
      width = 100, 
      height = 100, 
      units = "mm",
      dpi = dpi ,  bg = background_fill)
    
    dev.off()
  }
  
  
}





