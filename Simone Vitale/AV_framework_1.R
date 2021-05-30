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

## BUILD CART MODEL
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
#data <- df$Total_Power
w<- 96 
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
df_mp_MA<- mutate(df_mp_MA,original_MP=mp_power[['mp']])
df_mp_C<- mutate(df_mp_C,original_MP=mp_power[['mp']])

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
              
              MAB<- make_AV(leaf_series,w,'motion_artifact',T)
              
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
              mp_power<- find_discord(mp_power, n_discords = 4)
              mp_discord<-mp_power[['discord']][["discord_idx"]]
              df_mp_MAB$mp_discord <- ifelse(df_mp_MAB$X %in% mp_discord,1,NA)                   # c(mp_discord, rep(NA, nrow(df_mp)-length(mp_discord)))
              colnames(df_mp_MAB)[ncol(df_mp_MAB)] <- paste0("discord_", leaf_node_n[jj])
              
            }},
          
          M_A={
            
            # select one of the leaf node from df_time_series
            for (jj in c(1:(length(df_time_series)-1))) {
              
              mp_power<-NULL
              
              load("./data/mp_power.RData") # load to save time
              
              leaf_series<-as.vector(df_time_series[[jj]])
              
              MA<- make_AV(leaf_series,w,'motion_artifact',F)
              
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
              mp_power<- find_discord(mp_power, n_discords = 4)
              mp_discord<-mp_power[['discord']][["discord_idx"]]
              df_mp_MA$mp_discord <- ifelse(df_mp_MA$X %in% mp_discord,1,NA)                   # c(mp_discord, rep(NA, nrow(df_mp)-length(mp_discord)))
              colnames(df_mp_MA)[ncol(df_mp_MA)] <- paste0("discord_", leaf_node_n[jj])
              
            }},
          
          C={
            
            # select one of the leaf node from df_time_series
            for (jj in c(1:(length(df_time_series)-1))) {
              
              mp_power<-NULL
              
              load("./data/mp_power.RData") # load to save time
              
              leaf_series<-as.vector(df_time_series[[jj]])
              
              C<- make_AV(leaf_series,w,'complexity')
              
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
              
            }}
  )
}




# plot_AV_MAB

pp_plot<- list()

pp_plot[[1]] <- ggplot()+
  geom_line(data=df, aes(x=c(1:nrow(df)), y=Total_Power))+
  xlim(0,nrow(df))+
  scale_x_continuous(breaks = seq(0,nrow(df), by =100))+
  theme(axis.text.y = element_text(size = 6))


pp_plot[[2]] <-ggplot()+
  geom_line(data=df_mp_MAB, aes(x=X,y=original_MP))+
  xlim(0,nrow(df))


fields <- names(df_mp_MAB)

for (ii in c(1:(length(df_time_series)-1))) {
  
  
  pp_plot[[2+ii]]<-ggplot( aes(x=X), data = df_mp_MAB)
  
  loop_input_mp = paste("geom_line(aes(y=",fields[3*ii],"))", sep="")
  loop_input_av = paste("geom_line(aes(y= av_",leaf_node_n[ii],"*max(mp_annotated_",leaf_node_n[ii],")), color='blue')", sep="")
  
  pp_plot[[2+ii]] <- pp_plot[[2+ii]] + eval(parse(text=loop_input_mp))+ eval(parse(text=loop_input_av))
  
  # Get the start and end points for highlighted regions
  inds <- paste("diff(c(0, df_AV_color$color_node_",leaf_node_n[ii],"))",sep = "")
  inds<- eval((parse(text=inds)))
  start <- as.integer(paste(df_AV_color$X[inds == 1]))
  end <- df_AV_color$X[inds == -1]
  if (length(start) > length(end)) end <- c(end, tail(df_AV_color$X, 1))
  
  # highlight region data
  rects <- data.frame(start=start, end=end, group=seq_along(start))
  rects<-rects[c(1:(nrow(rects))-1),]
  
  
  pp_plot[[2+ii]]<- pp_plot[[2+ii]]+geom_rect(data=rects, inherit.aes=FALSE, aes(xmin=start, xmax=end, ymin=-Inf,
                                                                ymax=Inf, group=group), fill="orange", alpha=0.3)+
    xlim(0,nrow(df))
  
  
  
  
  
}
pp<-gridExtra::grid.arrange(grobs = pp_plot, ncol=1)
ggsave('pp.png', plot =pp,width=15,height=12)



dev.new()
ggarrange(p1,p2,p3,nrow = 3)
ggsave(file='./grafici/AV_MA.png')



