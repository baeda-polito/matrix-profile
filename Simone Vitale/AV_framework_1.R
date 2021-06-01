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
source(file = 'AV_plot_support.R')     #load customized function


# create a data frame, load data_tot.csv
#df <- read.csv("data/data_tot.csv")
load('data/df_univariate_small.Rdata')
df_univariate<- df_univariate %>% mutate(df_univariate, X=c(1:nrow(df_univariate)))

# df <- df %>%
#   mutate(Timestamp=as_datetime(Timestamp,tz='GMT')) %>%
#   mutate(Date=as.Date(Timestamp),
#          Year=year(Timestamp),
#          Month=month(Timestamp),
#          Day=day(Timestamp),
#          DayofWeek=wday(Timestamp),
#          Hour=hour(Timestamp),
#          Minute=minute(Timestamp),
#          Time=Hour+ (Minute/60))

## BUILD CART MODEL
rt <-rpart(data=df_univariate, Power_total ~ Time)

dev.new()
plot(as.party(rt), main = "REGRESSION TREE")

#extract leaf node number from rpart variable, rt
leaf_node_n <- which(rt[['frame']][['var']]=='<leaf>')

# add a column to df with leaf node number
df_univariate<- mutate(df_univariate, leaf_node_number=rt[['where']])


# the following analysis is restricted to a small time interval
# row_start <- 4000
# row_end<-row_start+(7*96)
# df<-df[c(row_start:row_end),]

# divide time series in as many interval as leaf node number
time_series <- matrix(nrow = nrow(df_univariate),ncol = length(leaf_node_n))
AV_color <- matrix(nrow = nrow(df_univariate),ncol = length(leaf_node_n))

for (ii in 1:length(leaf_node_n)) {
  
  time_series[1:nrow(df_univariate),ii]=df_univariate$Power_total
  AV_color[1:nrow(df_univariate),ii]=0
  
  for (jj in 1:nrow(df_univariate)) {
    
    if(df_univariate$leaf_node_number[jj]==leaf_node_n[ii]){
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
#data <- df_univariate$Power_total
#w<- 96 
w_AV_make <-4
#mp_power <- tsmp(data, window_size = w, verbose = 2)
#save(mp_power,file = './data/mp_power.Rdata')


# new df to store annotated mp
load("./data/mp_power.RData")
df_mp_MAB<- as.data.frame(c(1:nrow(mp_power[['mp']])))
df_mp_MA<- as.data.frame(c(1:nrow(mp_power[['mp']])))
df_mp_C<- as.data.frame(c(1:nrow(mp_power[['mp']])))

colnames(df_mp_MAB)[1] <-'X'
colnames(df_mp_MA)[1] <-'X'
colnames(df_mp_C)[1] <-'X'

df_mp_MAB<- mutate(df_mp_MAB,original_MP=mp_power[['mp']])
mp_power<- find_discord(mp_power, n_discords = 2)
mp_discord_original<-mp_power[['discord']][["discord_idx"]]
df_mp_MAB$mp_discord_original<- ifelse(df_mp_MAB$X %in% mp_discord_original,1,NA)   

df_mp_MA<- mutate(df_mp_MA,original_MP=mp_power[['mp']])
df_mp_MA$mp_discord_original<- ifelse(df_mp_MA$X %in% mp_discord_original,1,NA)

df_mp_C<- mutate(df_mp_C,original_MP=mp_power[['mp']])
df_mp_C$mp_discord_original<- ifelse(df_mp_C$X %in% mp_discord_original,1,NA)

# apply make_AV on original time series
av_type <- c("M_A_B", "M_A", "C" )


for (ii in 1:length(av_type)) {
  
  
  # depending on the type
  switch (av_type[ii],
          
          M_A_B= {
            
            # select one of the leaf node from df_time_series
            for (jj in c(1:(length(df_time_series)-1))) {
              
              mp_power<-NULL
              
              load("./data/mp_power.RData") # load to save time
              
              leaf_series<-as.vector(df_time_series[[jj]])
              
              MAB<- make_AV(leaf_series,w_AV_make,'motion_artifact',T)
              MAB<-MAB[c(1:nrow(mp_power[['mp']]))]
              
              # Apply AV to mp
              # add annotation vector to mp list
              mp_power$av <- MAB
              class(mp_power) <-tsmp:::update_class(class(mp_power), "AnnotationVector")
              mp_power <- tsmp::av_apply(mp_power)
              
              mp_annotated <- mp_power[['mp']]                                            # Create new columns
              AV <-mp_power[['av']]
              df_mp_MAB[ , ncol(df_mp_MAB) + 1] <- mp_annotated                                   # Append new column to df_mp
              colnames(df_mp_MAB)[ncol(df_mp_MAB)] <- paste0("mp_annotated_", leaf_node_n[jj])    # Rename column name
              df_mp_MAB[ , ncol(df_mp_MAB) + 1] <- AV   
              colnames(df_mp_MAB)[ncol(df_mp_MAB)] <- paste0("av_",leaf_node_n[jj] )
              
              # find discord
              mp_power<- find_discord(mp_power, n_discords = 2)
              mp_discord<-mp_power[['discord']][["discord_idx"]]
              df_mp_MAB$mp_discord <- ifelse(df_mp_MAB$X %in% mp_discord,1,NA)                   # c(mp_discord, rep(NA, nrow(df_mp)-length(mp_discord)))
              colnames(df_mp_MAB)[ncol(df_mp_MAB)] <- paste0("discord_", leaf_node_n[jj])
              
            }
            
            AV_plot_support(df_univariate,'M_A_B', df_mp_MAB,leaf_node_n,df_time_series,df_AV_color)},
          
          M_A={
            
            # select one of the leaf node from df_time_series
            for (jj in c(1:(length(df_time_series)-1))) {
              
              mp_power<-NULL
              
              load("./data/mp_power.RData") # load to save time
              
              leaf_series<-as.vector(df_time_series[[jj]])
              
              MA<- make_AV(leaf_series,w_AV_make,'motion_artifact',F)
              MA<-MA[c(1:nrow(mp_power[['mp']]))]
              
              # Apply AV to mp
              # add annotation vector to mp list
              mp_power$av <- MA
              class(mp_power) <-tsmp:::update_class(class(mp_power), "AnnotationVector")
              mp_power <- tsmp::av_apply(mp_power)
              
              mp_annotated <- mp_power[['mp']]                                            # Create new columns
              AV <-mp_power[['av']]
              df_mp_MA[ , ncol(df_mp_MA) + 1] <- mp_annotated                                   # Append new column to df_mp
              colnames(df_mp_MA)[ncol(df_mp_MA)] <- paste0("mp_annotated_", leaf_node_n[jj])    # Rename column name
              df_mp_MA[ , ncol(df_mp_MA) + 1] <- AV   
              colnames(df_mp_MA)[ncol(df_mp_MA)] <- paste0("av_",leaf_node_n[jj] )
              
              # find discord
              mp_power<- find_discord(mp_power, n_discords = 2)
              mp_discord<-mp_power[['discord']][["discord_idx"]]
              df_mp_MA$mp_discord <- ifelse(df_mp_MA$X %in% mp_discord,1,NA)                   # c(mp_discord, rep(NA, nrow(df_mp)-length(mp_discord)))
              colnames(df_mp_MA)[ncol(df_mp_MA)] <- paste0("discord_", leaf_node_n[jj])
              
            }
            AV_plot_support(df_univariate,'M_A', df_mp_MA,leaf_node_n,df_time_series,df_AV_color)},
          
          C={
            
            # select one of the leaf node from df_time_series
            for (jj in c(1:(length(df_time_series)-1))) {
              
              mp_power<-NULL
              
              load("./data/mp_power.RData") # load to save time
              
              leaf_series<-as.vector(df_time_series[[jj]])
              
              C<- make_AV(leaf_series,w_AV_make,'complexity')
              C<-C[c(1:nrow(mp_power[['mp']]))]
              
              # Apply AV to mp
              # add annotation vector to mp list
              mp_power$av <- C
              class(mp_power) <-tsmp:::update_class(class(mp_power), "AnnotationVector")
              mp_power <- tsmp::av_apply(mp_power)
              
              mp_annotated <- mp_power[['mp']]                                            # Create new columns
              AV <-mp_power[['av']]
              df_mp_C[ , ncol(df_mp_C) + 1] <- mp_annotated                                   # Append new column to df_mp
              colnames(df_mp_C)[ncol(df_mp_C)] <- paste0("mp_annotated_", leaf_node_n[jj])    # Rename column name
              df_mp_C[ , ncol(df_mp_C) + 1] <- AV   
              colnames(df_mp_C)[ncol(df_mp_C)] <- paste0("av_",leaf_node_n[jj] )
              
              # find discord
              mp_power<- find_discord(mp_power, n_discords = 2)
              mp_discord<-mp_power[['discord']][["discord_idx"]]
              df_mp_C$mp_discord <- ifelse(df_mp_C$X %in% mp_discord,1,NA)                   # c(mp_discord, rep(NA, nrow(df_mp)-length(mp_discord)))
              colnames(df_mp_C)[ncol(df_mp_C)] <- paste0("discord_", leaf_node_n[jj])
              
            }
            AV_plot_support(df_univariate,'C', df_mp_C,leaf_node_n,df_time_series,df_AV_color)}
  )
}











