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
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(df$X), 500))+
  labs(x='X', y='Power[KW]')


p2 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=V1),size=0.5, color='red')+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), 500))+
  labs(x='X', y='MP')

dev.new()
ggarrange(p1,p2,nrow = 2)

p3 <- p1+
  facet_wrap(~Month, scales = 'free')+
  geom_line(data =matrix_prof_tot,aes(x=X, y=V1*100),size=0.2, color='red')+
  scale_y_continuous(sec.axis=sec_axis(~./100, name='MP'))+
  theme(axis.line.y.right = element_line(color = "red"), axis.text.y.right = element_text(color='red'))

ggplotly(p3)

# A.V study
# av_hardlimit _artifact

av_hla <- av_hardlimit_artifact(mp, apply = TRUE)

matrix_prof_tot <- matrix_prof_tot %>%
  mutate(mp_hla=av_hla[["mp"]]) %>% 
  mutate(av_hla=av_hla[["av"]])



p4 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=mp_hla),size=0.5, color='magenta')+
  geom_line(data =matrix_prof_tot,aes(x=X, y=av_hla),size=0.5, color='blue')+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), 500))+
  labs(x='X', y='MP_with_AV')

fig_hla <- subplot(p1,p2,p4, nrows = 3,titleX = F,titleY = T)
fig_hla <- fig_hla %>% layout(title='AV HARDLIMIT ARTIFACT')

fig_hla

# av_complexity

av_compl <- av_complexity(mp, apply = TRUE)

matrix_prof_tot <- matrix_prof_tot %>%
  mutate(mp_compl=av_compl[["mp"]]) %>% 
  mutate(av_compl=av_compl[["av"]])



p5 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=mp_compl),size=0.5, color='magenta')+
  geom_line(data =matrix_prof_tot,aes(x=X, y=av_compl),size=0.5, color='green')+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), 500))+
  labs(x='X', y='MP_with_AV')

fig_compl <- subplot(p1,p2,p5, nrows = 3,titleX = F,titleY = T)
fig_compl <- fig_compl %>% layout(title='AV COMPLEXITY')

fig_compl























