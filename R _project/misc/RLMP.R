library(energydataset)
library(tsmp)
library(dplyr)
library(ggplot2)
library(ggpubr)

cat("\014")           # clears the console
rm(list = ls())       # remove all variables of the workspace

df <- energydataset::data_power_raw

df_univariate <- df %>%
  mutate(Timestamp = as.POSIXct(CET , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT")) %>%
  filter( Timestamp > "2015-05-01 00:00:00.0", Timestamp < "2015-07-01 00:00:00.0") %>%
  select(Timestamp, "1226")

w = 96

mp_univariate <- tsmp(df_univariate$`1226`, window_size = w, exclusion_zone = 1 )

plot(mp_univariate)

# find discord
discord <- find_discord(mp_univariate,
                        n_discords = 1,
                        n_neighbors = 1
)
discord_index <- as.numeric(discord$discord$discord_idx)
discord_n1_index <- as.numeric(discord$discord$discord_neighbor[[1]])

discord_df <- data.frame(
  data_index = c(df_mp_univariate$data_index[discord_index],
                 df_mp_univariate$data_index[discord_n1_index+w]
  ), 
  data = c(max(df_mp_univariate$data),
           max(df_mp_univariate$data)
  )-50, 
  label = c("Discord", "1st NN")
  
)

mp_length = length(mp_univariate$mp)

df_mp_univariate <- data.frame(
  data = df_univariate$`1226`[c(1:mp_length)],
  data_index = df_univariate$Timestamp[c(1:mp_length)],
  index =as.integer(rownames(df_univariate)[c(1:mp_length)]),
  mp = mp_univariate[[1]],
  mp_index = mp_univariate[[2]],
  rmp = mp_univariate[[3]],
  rmp_index = mp_univariate[[4]],
  lmp = mp_univariate[[5]],
  lmp_index = mp_univariate[[6]]
)


# plot original time series
p1 <- ggplot(df_mp_univariate, aes( x = data_index, y= data)) + 
  geom_line( ) + 
  labs( x = NULL , y = "Power [kW]") + 
  theme_bw() +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )+
  # discord
  annotate("rect", 
           xmin = df_mp_univariate$data_index[discord_index], 
           xmax = df_mp_univariate$data_index[discord_index+w], 
           ymin = 0, 
           ymax = max(df_mp_univariate$data),
           alpha = .5,fill = "red") +
  # nearest neighbor
  annotate("rect", 
           xmin = df_mp_univariate$data_index[discord_n1_index], 
           xmax = df_mp_univariate$data_index[discord_n1_index+w], 
           ymin = 0, 
           ymax = max(df_mp_univariate$data),
           alpha = .5,fill = "yellow") +
  geom_label(data = discord_df, aes(label = label))


# plot matrix profile
p2 <- ggplot( df_mp_univariate, aes(  x = index, y = mp)) + 
  geom_line( ) + 
  labs( x = NULL , y = "MP") + 
  theme_bw() +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )+
  # discord
  annotate("rect", xmin = discord_index, xmax = discord_index+w, ymin = 0, ymax = max(df_mp_univariate$mp),
           alpha = .5,fill = "red") + 
  # nearest neighbor
  annotate("rect", xmin = discord_n1_index, xmax = discord_n1_index+w, ymin = 0, ymax = max(df_mp_univariate$mp),
           alpha = .5,fill = "yellow")

# plot matrix profile
p3 <- ggplot( df_mp_univariate, aes(  x = index, y = rmp)) + 
  geom_line( ) + 
  labs( x = NULL , y = "R-MP") + 
  theme_bw() +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
        )+
  # discord
  geom_vline(xintercept = discord_index,
             color = "red", size=0.5)+
  # nearest neighbor
  geom_vline(xintercept = discord_n1_index,
             color = "yellow", size=0.5)

# plot matrix profile

p4 <- ggplot( df_mp_univariate, aes(  x = index, y = lmp)) + 
  geom_line( ) + 
  labs( x = "Index" , y = "L-MP") + 
  theme_bw() +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )+
  # discord
  geom_vline(xintercept = discord_index,
             color = "red", size=0.5)+
  # nearest neighbor
  geom_vline(xintercept = discord_n1_index, 
             color = "yellow", size=0.5)

dev.new()
ggarrange(p1, p2, p3, p4, 
          ncol = 1, nrow = 4,
          align = "v")
#dev.off()


### plot discords
### 
### 


dev.new()
pd1 <- ggplot() + 
  geom_line( data = df_mp_univariate %>% filter(index >= discord_index,  index <= discord_index+w) , aes( x = c(0:w), y = data),  color = "red"  ) + 
  geom_line( data = df_mp_univariate %>% filter(index >= discord_n1_index,  index <= discord_n1_index+w) , aes( x = c(0:w), y = data), color = "yellow"  ) + 
  labs( x = NULL , y = "Power [kW]") + 
  theme_bw() +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  )

pd1









