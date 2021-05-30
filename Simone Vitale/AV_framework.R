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


# the following analysis is restricted to a small time interval
row_start <- 4000
row_end<-row_start+(7*96)
df<-df[c(row_start:row_end),]

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

data <- df$Total_Power

w<- 96 

mp_power <- tsmp(data, window_size = w, verbose = 2)

#save(mp_power,file = './data/mp_power.Rdata')

# new df to store annotated mp

load("./data/mp_power.RData")

df_mp <- as.data.frame(c(1:nrow(mp_power[['mp']])))

colnames(df_mp)[1] <-'X'

df_mp<- mutate(df_mp,original_MP=mp_power[['mp']])


# select one of the leaf node from df_time_series
leaf<-df_time_series$leaf_node_9
 
# apply make_AV on original time series
av_type <- c("M_A_B", "M_A", "C" )

annotation<-NULL

for (ii in 1:length(av_type)) {
  
  load("./data/mp_power.RData") # load to save time
  
  
  # depending on the type
  switch (av_type[ii],
          
          M_A_B= {M_A_B  <- make_AV(leaf,w,'motion_artifact',T)
          annotation=M_A_B},
          
          M_A={M_A<- make_AV(leaf,w,'motion_artifact',F)
          annotation=M_A},
          
          C={C <- make_AV(leaf,w,'complexity')
          annotation=C}
          
  )
  
  # Apply AV to mp
  # add annotation vector to mp list
  mp_power$av <- annotation
  class(mp_power) <-tsmp:::update_class(class(mp_power), "AnnotationVector")
  mp_power <- tsmp::av_apply(mp_power)
  
  
  
  mp_annotated <- mp_power[['mp']]                                        # Create new columns
  AV <-mp_power[['av']]
  df_mp[ , ncol(df_mp) + 1] <- mp_annotated                               # Append new column to df_mp
  colnames(df_mp)[ncol(df_mp)] <- paste0("mp_annotated_", av_type[ii])    # Rename column name
  df_mp[ , ncol(df_mp) + 1] <- AV   
  colnames(df_mp)[ncol(df_mp)] <- paste0("av_", av_type[ii])
  
  # find discord
  mp_power<- find_discord(mp_power, n_discords = 4)
  mp_discord<-mp_power[['discord']][["discord_idx"]]
  df_mp$mp_discord <- ifelse(df_mp$X %in% mp_discord,1,NaN)                                      # c(mp_discord, rep(NA, nrow(df_mp)-length(mp_discord)))
  colnames(df_mp)[ncol(df_mp)] <- paste0("discord_", av_type[ii])
  
}

