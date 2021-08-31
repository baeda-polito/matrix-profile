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
library(NbClust)

# try to define groups in unsupervided way through cluster

df <-  read.csv(file.path(dirname(dirname(getwd())), "Simone Deho", "df_cabinaC_2019_labeled.csv"), sep = ',') %>%
  dplyr::select(Date, Day_Type, Holiday) %>%
  unique()

# load dataset for cluster
df1 <-  read.csv(file.path(dirname(dirname(getwd())), "Simone Deho", "df_cabinaC_2019_labeled.csv"), sep = ',') %>%
  dplyr::select(Date, Time, Total_Power)

# spread on hours
df2 <- tidyr::spread(df1, Time, Total_Power)    # mette sulle righe i giorni e colonne i 15 min orari

# load dataset of sub daily context
context_df <- read.csv(file.path("Polito_Usecase", "data", "time_window.csv"))

# select only hours columns
# data <- df2[,2:97] # all
# try to cluster by context
data <- df2[,2:context_df$observations[1]]
data <- df2[,(context_df$observations[1]+1) : (context_df$observations[1]+1+context_df$observations[2]+1)]

# caluclate dissimilarity matrix
diss_matrix <- dist(data, method = "euclidean")      

# define number of clusters
n_clusters <-  6 # supervised
Nb_res <- NbClust(data, diss = diss_matrix, distance = NULL, min.nc = 2, max.nc = 8, method = "complete", index = "silhouette")
n_clusters <- length(unique(Nb_res$Best.partition))


# do cluster
hcl <- hclust(diss_matrix, method = "ward.D2") 

# plot dendogram
dev.new()
png(file = file.path("Polito_Usecase", "figures", "groups_dendogram.png"), bg = "white", width = 900, height = 500)                   # to save automatically image in WD
plot(hcl, family = font_family)
rect.hclust(hcl, k = n_clusters, border = "red")
dev.off()

# add cluster id to total dataframe
df2$cluster <- cutree(hcl, n_clusters) 
# merge with previous to add calendar variables etc
df2 <- merge.data.frame(df2, df)

################# fix clusters
# move sunday in 1
df2 <- mutate(df2, cluster = ifelse(Day_Type == 7, 1, cluster))
# move saturday in 3
df2 <- mutate(df2, cluster = ifelse(Day_Type == 6 & cluster != 1, 3, cluster))
# move 6 in 4
# df2 <- mutate(df2, cluster = ifelse(cluster == 6, 4, cluster))
# move 2 in 5
# df2 <- mutate(df2, cluster = ifelse(cluster == 2, 5, cluster))


df1 <- merge.data.frame(df1, df2[c("Date", "cluster")]) 
centr <- plyr::ddply(df1, c("cluster","Time"), summarise, Total_Power = mean(Total_Power)) 

counted <- df1 %>%
  group_by(cluster) %>%
  count() %>%
  mutate(n = n/96)

df1_plot <- merge.data.frame(df1, counted) %>%
  mutate(cluster_label = paste("Cluster ", cluster, " (", n," profiles)", sep = ""),
         cluster_label = as.factor(cluster_label))

centr_plot <- merge.data.frame(centr, counted) %>%
  mutate(cluster_label = paste("Cluster ", cluster, " (", n," profiles)", sep = ""),
         cluster_label = as.factor(cluster_label))


dev.new()
ggplot() +
  geom_line(data = df1_plot, 
            aes(x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") , y = Total_Power, group = Date) , 
            color = "gray", alpha = 0.3, size = 0.7) +
  geom_line(data = centr_plot, 
            aes(x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") , y = Total_Power, color = cluster_label) , 
            size = 1) +
  scale_x_datetime(expand = c(0,0), labels = date_format("%H:%M" , tz = "GMT"), breaks = date_breaks("4 hour")) +
  scale_y_continuous(limits = c(0,ceiling(max(df1_plot$Total_Power)/100)*100), expand = c(0,0)) +
  theme_bw() +
  facet_wrap(~cluster_label) +
  labs(title = "Daily Profile Cluster Results",
       subtitle = "Identification of 6 similarity groups for CMP analysis",
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
  
  
  ggsave(filename = file.path("Polito_Usecase", "figures", "groups_clusters.png"), width = 9, height = 5.5, dpi = 200 )

dev.off()


library(mltools)
library(data.table)

dt <- data.table(
  timestamp = df2$Date,
  Cluster = as.factor(df2$cluster)
) %>%
  one_hot()

df_py_holiday <- as.data.frame(dt) %>%
  mutate(across(is.numeric, as.logical))


write.csv(df_py_holiday, file =  file.path("Polito_Usecase", "data", "polito_holiday.csv") , row.names = FALSE)




