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
 data <- df$X1226
 #mp <- tsmp(data, window_size = w, verbose = 2)

 #save(mp,file = './data/mp_total.Rdata')
 
 load('./data/mp_total.Rdata')
 p1 <-ggplot()+
         geom_line(data =df,aes(x=X, y=X1226),size=0.5)+
         theme_bw()
 
 matrix_prof_tot <- as.data.frame(mp[[1]])
 matrix_prof_tot <- matrix_prof_tot %>%
         mutate(X=c(1:nrow(matrix_prof_tot))) %>%
         mutate(Month=df$Month[c(1:nrow(matrix_prof_tot))])
         
 

 p2 <-ggplot()+
         geom_line(data =matrix_prof_tot,aes(x=X, y=V1),size=0.5)+
         theme_bw()
 
 dev.new()
 ggarrange(p1,p2,nrow = 2)
 
 p3 <- p1 +
         facet_wrap(~Month, scales = 'free')+
         
         geom_line(data =matrix_prof_tot,aes(x=X, y=V1*100),size=0.2, color='red')+
         scale_y_continuous(sec.axis=sec_axis(~./100),)+
         theme(axis.line.y.right = element_line(color = "red"))
              
 dev.new()
 plot(p3)

# find motifs subsequence
 
 motif_subseq<-motifs(
   mp,
   exclusion_zone = 1/2,
   k = 4,
   neighbor_count = 3,
   radius = 4
 )
 
 #for(ii in c(1:nrow(motif_subseq[["motif"]][["motif_neighbor"]])))
 
 
dev.new()
plot(motif_subseq)


#mp <- tsmp(data, window_size = w, verbose = 2)
#save(mp,file = './data/mp_total.Rdata')
load('./data/mp_total.Rdata')

matrix_prof_tot <- as.data.frame(mp[[1]])

matrix_prof_tot <- matrix_prof_tot %>%
  mutate(X=c(1:nrow(matrix_prof_tot))) %>%
  mutate(Month=df$Month[c(1:nrow(matrix_prof_tot))])

xticks=100


p1 <-ggplot()+
  geom_line(data =df,aes(x=X, y=X1226),size=0.5)+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(df$X), xticks))+
  labs(x='X', y='Power[KW]')


p2 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=V1),size=0.5, color='red')+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X),xticks ))+
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
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), xticks))+
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
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), xticks))+
  labs(x='X', y='MP_with_AV')

fig_compl <- subplot(p1,p2,p5, nrows = 3,titleX = F,titleY = T)
fig_compl <- fig_compl %>% layout(title='AV COMPLEXITY')

fig_compl

# av_motion_artifact

av_ma <- av_motion_artifact(mp, apply = TRUE)

matrix_prof_tot <- matrix_prof_tot %>%
  mutate(mp_ma=av_ma[["mp"]]) %>% 
  mutate(av_ma=av_ma[["av"]])

plot(av_ma$av, type = "l")


av_list <- make_AV(av_ma$data[[1]], 96)

plot(av_list$AV, type = "l")


p6 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=mp_ma),size=0.5, color='magenta')+
  geom_line(data =matrix_prof_tot,aes(x=X, y=av_ma),size=0.5, color='purple')+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), xticks))+
  labs(x='X', y='MP_with_AV')

fig_ma <- subplot(p1,p2,p6, nrows = 3,titleX = F,titleY = T)
fig_ma <- fig_ma %>% layout(title='AV MOTION ARTIFACT')

fig_ma

# av_stop_word

av_sw <- av_stop_word(mp,stop_word_loc = 100, apply = TRUE)

matrix_prof_tot <- matrix_prof_tot %>%
  mutate(mp_sw=av_sw[["mp"]]) %>% 
  mutate(av_sw=av_sw[["av"]])



p7 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=mp_sw),size=0.5, color='magenta')+
  geom_line(data =matrix_prof_tot,aes(x=X, y=av_sw),size=0.5, color='brown')+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), xticks))+
  labs(x='X', y='MP_with_AV')

fig_sw <- subplot(p1,p2,p7, nrows = 3,titleX = F,titleY = T)
fig_sw <- fig_sw %>% layout(title='AV STOP WORD')

fig_sw

# av_zerocrossing

av_zc <- av_zerocrossing(mp, apply = TRUE)

matrix_prof_tot <- matrix_prof_tot %>%
  mutate(mp_zc=av_zc[["mp"]]) %>% 
  mutate(av_zc=av_zc[["av"]])



p8 <-ggplot()+
  geom_line(data =matrix_prof_tot,aes(x=X, y=mp_zc),size=0.5, color='magenta')+
  geom_line(data =matrix_prof_tot,aes(x=X, y=av_zc),size=0.5, color='gold')+
  theme(axis.text.x = element_text(angle=-90),
        panel.grid.major.x =element_line( size=.1, color = 'black'))+
  scale_x_continuous(breaks = seq(0, length(matrix_prof_tot$X), xticks))+
  labs(x='X', y='MP_with_AV')

fig_zc <- subplot(p1,p2,p8, nrows = 3,titleX = F,titleY = T)
fig_zc <- fig_zc %>% layout(title='AV ZERO CROSSING')

fig_zc




















