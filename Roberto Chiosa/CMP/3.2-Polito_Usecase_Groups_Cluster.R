#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")

import::from(magrittr, "%>%")
import::from(dplyr, select, mutate, group_by, count, across, summarise)
import::from(tidyr, pivot_wider)
import::from(NbClust, NbClust)
import::from(data.table, data.table)
import::from(mltools, one_hot)
import::from(plyr,ddply)
library(ggplot2)
library(scales)

###### DATASET PRE-PROCESSING:
#   - Load df for Date, Day_type and Holiday info
#   - Load df1 for clustering
#   - Spread df1 into df2 for clustering
#   - Select only values in data from df2

df <-  read.csv(file.path(getwd(),"Polito_Usecase", "data",  "polito_labeled.csv"), sep = ',', dec = ".") %>%
  select(Date, Day_Type, Holiday) %>%
  unique()

df1 <-  read.csv(file.path(getwd(),"Polito_Usecase", "data",  "polito_labeled.csv"), sep = ',', dec = ".") %>%
  dplyr::select(Date, Time, Total_Power) 

df2 <- pivot_wider(df1, names_from = "Time", values_from = "Total_Power")

data <- select(df2, -Date)

###### CLUSTERING
#   - Dissimilarity matrix with euclidean distance
#   - Set number of clusters
#   - Perform cluster

diss_matrix <- dist(data, method = "euclidean")      

n_clusters <-  6 # supervised
#Nb_res <- NbClust(data, diss = diss_matrix, distance = NULL, min.nc = 2, max.nc = 8, method = "ward.D2", index = "all")
#n_clusters <- length(unique(Nb_res$Best.partition))

# Do cluster
hcl <- hclust(diss_matrix, method = "ward.D2") 

# plot dendogram
dev.new()
png(file = file.path("Polito_Usecase", "figures", "groups_dendogram.jpg"), bg = "white", width = 900, height = 500)                   # to save automatically image in WD
plot(hcl, family = font_family)
rect.hclust(hcl, k = 4, border = "red")
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
# merge clusters
df2 <- mutate(df2, cluster = ifelse(cluster == 5 | cluster == 6, 4, cluster))


df1 <- merge.data.frame(df1, df2[c("Date", "cluster")]) 
centr <- ddply(df1, c("cluster","Time"), summarise, Total_Power = mean(Total_Power)) 

# create a counting dataframe
counted <- df1 %>%
  group_by(cluster) %>%
  count() %>%
  mutate(n = n/96)


# profiles dataframe
df1_plot <- merge.data.frame(df1, counted) %>%
  mutate(cluster_label = paste("Cluster ", cluster, " (", n," profiles)", sep = ""),
         cluster_label = as.factor(cluster_label))

# centroid dataframe
centr_plot <- merge.data.frame(centr, counted) %>%
  mutate(cluster_label = paste("Cluster ", cluster, " (", n," profiles)", sep = ""),
         cluster_label = as.factor(cluster_label))

plot <- ggplot() +
  geom_line(data = df1_plot, 
            aes(x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") , y = Total_Power, group = Date) , 
            color = "#D5D5E0", alpha = 0.3, size = 0.7) +
  geom_line(data = centr_plot, 
            aes(x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") , y = Total_Power, color = cluster_label) , 
            size = 1) +
  #scale_color_manual(values = c("#D83C3B", "#3681A9", "#87CD93","#FA9A4E") ) +
  scale_x_datetime(expand = c(0,0), labels = date_format("%H:%M" , tz = "GMT"), breaks = date_breaks("4 hour")) +
  scale_y_continuous(limits = c(0,ceiling(max(df1_plot$Total_Power)/100)*100), expand = c(0,0)) +
  theme_bw() +
  facet_wrap(~cluster_label, nrow= 1) +
  labs(
    #title = "Daily Profile Cluster Results",
    #subtitle = "Identification of 6 similarity groups for CMP analysis",
    x = "" , 
    y = "Power [kW]"
  )+
  theme_minimal() +
  ggplot2::theme(
    text = element_text(family = font_family),
    plot.title = element_text(hjust = 0.5, size = fontsize_large, margin = margin(t = 0, r = 0, b = 0, l = 0), ),
    plot.subtitle = element_text(hjust = 0.5, size = fontsize_small, margin = margin(t = 5, r = 5, b = 10, l = 10)),
    # legend
    legend.position = "none",                     # legend position on the top of the graph
    # strip.text = element_text(size = 17), # facet wrap title fontsize
    # AXIS X
    #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.x = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 5, l = 5), angle = 45, vjust=.3),
    # AXIS Y
    #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.y = element_text(size = fontsize_small, margin = margin(t = 5, r = 5, b = 0, l = 5), angle = 0, vjust=.3),
    # background
    panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
    #panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
    panel.grid.minor = element_blank(),            # draws nothing, and assigns no space.
    plot.margin = unit(c(plot_margin,plot_margin,plot_margin,plot_margin), "cm")
  ) 


# plot horizontal labeled
dev.new()
plot
ggsave(filename = file.path("Polito_Usecase", "figures", "groups_clusters.jpg"), 
       width = 10, height = 3, dpi = dpi,  bg = background_fill)
dev.off()

# # plot void
# dev.new()
# plot + theme_void()
# ggsave(filename = file.path("Polito_Usecase", "figures", "groups_clusters_4cmp.jpg"),
#        width = 20, height = 3, dpi = dpi ,  bg = background_fill)
# 
# dev.off()

###### EXPORT RESULTS
#   - Create a one hot encoding of clusterf by date
#   - Convert to boolean
#   - Save

group_cluster <- data.table(
  timestamp = df2$Date,
  Cluster = as.factor(df2$cluster)
) %>%
  one_hot() %>%
  as.data.frame()%>%
  mutate(across(where(is.numeric), as.logical))

write.csv(group_cluster, file =  file.path("Polito_Usecase", "data", "group_cluster.csv") , row.names = FALSE)




