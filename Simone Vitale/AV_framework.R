# this script performs an AV framework which involves combined use of CART and customized AV function
library(rpart) #CART
library(partykit)
library(lubridate) # makes it easier to work with dates and times
library(dplyr)# manipulate data, mutate()
library(magrittr) #%>% pipe operator
source(file = 'make_AV.R') #load customized function

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

for (ii in 1:length(leaf_node_n)) {
  
  time_series[1:nrow(df),ii]=df$Total_Power
  
  for (jj in 1:nrow(df)) {
    
    if(df$leaf_node_number[jj]==leaf_node_n[ii]){
      time_series[jj,ii]=time_series[jj,ii]
    }
    else{
      time_series[jj,ii]=0
      
    }
  }
}

# create a df with previous matrix
df_time_series <- as.data.frame(time_series)

#rename columns 
names(df_time_series)<-paste0("leaf_node_", leaf_node_n)

#call make_AV with local variable
w<- 96*7  
AV <-make_AV(df_time_series$leaf_node_2,w,'motion_artifact',F)
 
plot(AV,type = 'l')  












