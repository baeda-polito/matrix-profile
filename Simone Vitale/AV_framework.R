# this script performs an AV framework which involves combined use of CART and customized AV function
library(rpart)                 #CART
library(partykit)
library(lubridate)             # makes it easier to work with dates and times
library(dplyr)                 # manipulate data, mutate()
library(magrittr)              #%>% pipe operator
library(ggplot2)               # to plot
library(ggpubr)
library(plotly)
library(tsmp)                  #MP
library(htmlwidgets)
source(file = 'make_AV.R')     #load customized function



# create a data frame, load data_tot.csv
df <- read.csv("data/data_tot.csv")

df <- df %>%
  mutate(Timestamp=as_datetime(Timestamp,tz='GMT')) %>%
  mutate(Date=as.Date(Timestamp),
         Year=year(Timestamp),
         Month=month(Timestamp),
         Day=day(Timestamp),
         DayofWeek=wday(Timestamp),
         Hour=hour(Timestamp),
         Minute=minute(Timestamp),
         Time=Hour+ (Minute/60))

# build CART model

rt <-rpart(data=df, Total_Power ~ Time)

dev.new()
plot(as.party(rt), main = "REGRESSION TREE")

#extract leaf node number from rpart variable, rt

leaf_node_n <- which(rt[['frame']][['var']]=='<leaf>')

# add a column to df with leaf node number

df<- mutate(df, leaf_node_number=rt[['where']])


# divide time series in as many interval as leaf node number
time_series <- matrix(nrow = nrow(df),ncol = length(leaf_node_n))
AV_color <- matrix(nrow = nrow(df),ncol = length(leaf_node_n))

for (ii in 1:length(leaf_node_n)) {
  
  time_series[1:nrow(df),ii]=df$Total_Power
  AV_color[1:nrow(df),ii]=0
  
  for (jj in 1:nrow(df)) {
    
    if(df$leaf_node_number[jj]==leaf_node_n[ii]){
      time_series[jj,ii]=time_series[jj,ii]
      AV_color[jj,ii]=1
    }
    else{
      time_series[jj,ii]=0
      
    }
  }
}

# create a df with previous matrix
df_time_series <- as.data.frame(time_series)
df_AV_color <- as.data.frame(AV_color)


#rename columns 
names(df_time_series)<-paste0("leaf_node_", leaf_node_n)
df_time_series <-mutate(df_time_series,X=c(1:nrow(df_time_series)))


names(df_AV_color)<-paste0("color_node_",leaf_node_n )
df_AV_color<-mutate(df_AV_color,X=c(1:nrow(df_AV_color)))


#make MP on time series

#data <- df$Total_Power

w<- 96*7  

#mp_power_tot_sett <- tsmp(data, window_size = w, verbose = 2)

#save(mp_power_tot_sett,file = './data/mp_power_tot_sett.Rdata')

# new df to store annotated mp

load("./data/mp_power_tot_sett.RData")

df_mp <- as.data.frame(c(1:nrow(mp_power_tot_sett[['mp']])))

colnames(df_mp)[1] <-'X'

df_mp<- mutate(df_mp,original_MP=mp_power_tot_sett[['mp']])


# select one of the leaf node from df_time_series
leaf<-df_time_series$leaf_node_9
 
# apply make_AV on original time series
av_type <- c("M_A_B", "M_A", "C" )

annotation<-NULL

for (ii in 1:length(av_type)) {
  
  load("./data/mp_power_tot_sett.RData") # load to save time
  
  
  # depending on the type
  switch (av_type[ii],
          
          M_A_B= {M_A_B  <- make_AV(leaf,w,'motion_artifact',T)
          annotation=M_A_B},
          
          M_A={M_A<- make_AV(leaf,w,'motion_artifact',F)
          annotation=M_A},
          
          C={C <- make_AV(leaf,w,'complexity')
          annotation=C}
          
  )
  
  ## Apply AV to mp
  # add annotation vector to mp list
  mp_power_tot_sett$av <- annotation
  class(mp_power_tot_sett) <-tsmp:::update_class(class(mp_power_tot_sett), "AnnotationVector")
  mp_power_tot_sett <- tsmp::av_apply(mp_power_tot_sett)
  
  
  
  mp_annotated <- mp_power_tot_sett[['mp']]                               # Create new columns
  AV <-mp_power_tot_sett[['av']]
  df_mp[ , ncol(df_mp) + 1] <- mp_annotated                               # Append new column to df_mp
  colnames(df_mp)[ncol(df_mp)] <- paste0("mp_annotated_", av_type[ii])    # Rename column name
  df_mp[ , ncol(df_mp) + 1] <- AV   
  colnames(df_mp)[ncol(df_mp)] <- paste0("av_", av_type[ii])
  
  # find discord
  mp_power_tot_sett<- find_discord(mp_power_tot_sett)
  mp_discord<-mp_power_tot_sett[['discord']][["discord_idx"]]
  df_mp[length(mp_discord) , ncol(df_mp) + 1] <- mp_discord 
  colnames(df_mp)[ncol(df_mp)] <- paste0("discord_", av_type[ii])
  
}

write.csv(df_mp,"./data/df_mp.csv", row.names = FALSE)

# plot_AV_MAB

p1 <- ggplot()+
  geom_line(data=df, aes(x=Date, y=Total_Power))+
  theme_bw()

p2 <-ggplot()+
  geom_line(data=df_mp, aes(x=X,y=original_MP))+
  theme_bw()

p3 <-ggplot()+
  geom_line(data=df_mp, aes(x=X,y=mp_annotated_M_A_B))+
  geom_line(data = df_mp, aes(x=X, y=av_M_A_B*max(df_mp$mp_annotated_M_A_B)),color='blue')+
  scale_y_continuous(sec.axis=sec_axis(~./max(df_mp$mp_annotated_M_A_B), name='AV'))+
  geom_point(data=df_mp, aes(x=df_mp$discord_M_A_B[1],y=mp_annotated_M_A_B[df_mp$discord_M_A_B[1]]),color='red')

# Get the start and end points for highlighted regions
inds <- diff(c(0, df_AV_color$color_node_2))
start <- df_AV_color$X[inds == 1]
end <- df_AV_color$X[inds == -1]
if (length(start) > length(end)) end <- c(end, tail(df_AV_color$X, 1))

# highlight region data
rects <- data.frame(start=start, end=end, group=seq_along(start))

p3 <-p3+
  geom_rect(data=rects, inherit.aes=FALSE, aes(xmin=start, xmax=end, ymin=-Inf,
                                               ymax=Inf, group=group), fill="orange", alpha=0.3)


dev.new()
ggarrange(p1,p2,p3,nrow = 3)
ggsave(file='./grafici/AV_MAB.pdf')


# plot_AV_MA

p1 <- ggplot()+
  geom_line(data=df, aes(x=Date, y=Total_Power))+
  theme_bw()

p2 <-ggplot()+
  geom_line(data=df_mp, aes(x=X,y=original_MP))+
  theme_bw()

p3 <-ggplot()+
  geom_line(data=df_mp, aes(x=X,y=mp_annotated_M_A))+
  geom_line(data = df_mp, aes(x=X, y=av_M_A*max(df_mp$mp_annotated_M_A)),color='blue')+
  scale_y_continuous(sec.axis=sec_axis(~./max(df_mp$mp_annotated_M_A), name='AV'))+
  geom_point(data=df_mp, aes(x=df_mp$discord_M_A[1],y=mp_annotated_M_A[df_mp$discord_M_A[1]]),color='red')


dev.new()
ggarrange(p1,p2,p3,nrow = 3)
ggsave(file='./grafici/AV_MA.pdf')

html<-subplot(p1, p2, p3, nrows = 3)
htmlwidgets::saveWidget(as_widget(html), "./grafici/AV_MA.html")






  
 













