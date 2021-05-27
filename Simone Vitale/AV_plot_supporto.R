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

df <- read.csv("data/data_tot.csv")
df_mp <- read.csv("data/df_mp_nodo1.csv")

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


# plot_AV_C

p1 <- ggplot()+
  geom_line(data=df, aes(x=Date, y=Total_Power))+
  theme_bw()

p2 <-ggplot()+
  geom_line(data=df_mp, aes(x=X,y=original_MP))+
  theme_bw()

p3 <-ggplot()+
  geom_line(data=df_mp, aes(x=X,y=mp_annotated_C))+
  geom_line(data = df_mp, aes(x=X, y=av_M_A*max(df_mp$mp_annotated_C)),color='blue')+
  scale_y_continuous(sec.axis=sec_axis(~./max(df_mp$mp_annotated_C), name='AV'))+
  geom_point(data=df_mp, aes(x=df_mp$discord_C[1],y=mp_annotated_C[df_mp$discord_C[1]]),color='red')


dev.new()
ggarrange(p1,p2,p3,nrow = 3)
ggsave(file='./grafici/AV_C.pdf')

html<-subplot(p1, p2, p3, nrows = 3)
htmlwidgets::saveWidget(as_widget(html), "./grafici/AV_C.html")






