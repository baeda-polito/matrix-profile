#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
library(magrittr)
library(dplyr)
library(lubridate)
library(rpart)
library(partykit)
library(ggplot2)
library(scales)

# try to define daily context in unsupervided way through CART

df <-  read.csv('/Users/robi/Desktop/matrix_profile/Simone Deho/df_cabinaC_2019_labeled.csv', sep = ',') %>%
  dplyr::select(Date, Day_Type, Holiday) %>%
  unique()

df1 <-  read.csv('/Users/robi/Desktop/matrix_profile/Simone Deho/df_cabinaC_2019_labeled.csv', sep = ',') %>%
  dplyr::select(Date, Time, Total_Power)

df2 <- tidyr::spread(df1, Time, Total_Power)    # mette sulle righe i giorni e colonne i 15 min orari
data <- df2[,2:97]

diss_matrix <- dist(data, method = "euclidean")      

n_clusters <-  6
hcl <- hclust(diss_matrix, method = "ward.D2") 
dev.new()
png(file = "./Polito_Usecase/figures/groups_dendogram.png", bg = "white", width = 500, height = 500)                   # to save automatically image in WD
plot(hcl)
rect.hclust(hcl, k = n_clusters, border = "red")
dev.off()

df2$cluster <- cutree(hcl, n_clusters) 
df2 <- merge.data.frame(df2, df)

# fix clusters
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

cl_plot <- ggplot() +
  geom_line(data = df1, aes(x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") , y = Total_Power, group = Date) , color = "grey", size = 0.7) +
  geom_line(data = centr, aes(x = as.POSIXct(Time, format = "%H:%M:%S" , tz = "GMT") , y = Total_Power, color = as.factor(cluster)) , size = 1) +
  scale_x_datetime(expand = c(0,0), labels = date_format("%H:%M" , tz = "GMT"), breaks = date_breaks("4 hour")) +
  scale_y_continuous(limits = c(0,ceiling(max(df1$Total_Power)/100)*100), expand = c(0,0)) +
  theme_bw() +
  facet_wrap(~cluster) +
  ggplot2::theme(legend.text = element_text(size = 20),
                 legend.position = "top", 
                 legend.key.width = unit(2, "cm"),
                 legend.key.height = unit(1, "cm"),
                 legend.direction = "horizontal",
                 legend.box = "vertical",
                 legend.title = element_text(size = 20),
                 axis.title.x = element_text(size = 20, margin = margin(t = 20, r = 20, b = 0, l = 0)),
                 axis.title.y = element_text(size = 20, margin = margin(t = 20, r = 20, b = 0, l = 0)),
                 axis.text.x = element_text(size = 15, angle = 45, vjust = .5),
                 axis.text.y = element_text(size = 15 , vjust = .3),
                 panel.background = element_rect(fill = "white")
  ) +
  guides(colour = guide_legend(override.aes = list(size = 10))) +
  labs(x = "Hour" , y = "Power", color = "Cluster")

dev.new()
png(file = "./Polito_Usecase/figures/groups_clusters.png", bg = "white", width = 500, height = 500)                   # to save automatically image in WD
plot(cl_plot)
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

write.csv(df_py_holiday, file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/CMP/Polito_Usecase/data/polito_holiday.csv", row.names = FALSE)




