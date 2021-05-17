library(rpart)
library(MLmetrics)
library(magrittr)
library(plyr)
library(dplyr)
library(tidyr)
library(scales)
library(imputeTS)
library(ggplot2)
library(ggpubr)
library(tsmp)
library(plotly)

df <- read.csv("data/df.csv")

# My first MP 

data <- df$X1226
w <- 96

#mp <- tsmp(data, window_size = w, verbose = 2)
#save(mp,file = './data/mp_total.Rdata')
load('./data/mp_total.Rdata')

matrix_prof_tot <- as.data.frame(mp[[1]])

matrix_prof_tot <- matrix_prof_tot %>%
  mutate(X=c(1:nrow(matrix_prof_tot))) %>%
  mutate(Month=df$Month[c(1:nrow(matrix_prof_tot))])


p1 <-ggplot()+
  geom_line(data =df,aes(x=X, y=X1226),size=0.5)+
  theme_bw()+
  labs(x='X', y='Power[KW]')

p2 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=V1),size=0.5, color='red')+
  theme_bw()+
  labs(x='X', y='MP')

dev.new()
ggarrange(p1,p2,nrow = 2)

p3 <- p1+
  facet_wrap(~Month, scales = 'free')+
  geom_line(data =matrix_prof_tot,aes(x=X, y=V1*100),size=0.2, color='red')+
  scale_y_continuous(sec.axis=sec_axis(~./100, name='MP'))+
  theme(axis.line.y.right = element_line(color = "red"), axis.text.y.right = element_text(color='red'))

ggplotly(p3)











# find motifs subsequence

motif_subseq<-motifs(
  mp,
  exclusion_zone = 1/2,
  k = 4,
  neighbor_count = 3,
  radius = 4
)












