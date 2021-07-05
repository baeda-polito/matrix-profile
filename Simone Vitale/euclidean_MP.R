#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace

library(tsmp)               #MP
library(magrittr)           #%>% pipe operator
library(dplyr)              # manipulate data, mutate()
library(ggplot2)            # to plot
library(egg)                # ggarrange()
library(rpatrec)            #noise function

#  EUCLIDEAN MATRIX PROFILE ------------------------------------------------------------------

df <- read.csv( "../Roberto Chiosa/Python_project/data/df_univariate_small.csv")

mp_euclidean <- read.csv(file = "../Roberto Chiosa/Python_project/data/mp_euclidean.csv",
                         col.names = c("row","mp", "pi", "lpi", "rpi")) %>%
  dplyr::mutate(row = row-1)

mp_euclidean$row <- NULL
mp_euclidean <- as.list(mp_euclidean)
mp_euclidean$mp <- as.matrix(mp_euclidean$mp)
mp_euclidean$pi <- as.matrix(mp_euclidean$pi)
mp_euclidean$lpi <- as.matrix(mp_euclidean$lpi)
mp_euclidean$rpi <- as.matrix(mp_euclidean$rpi)
mp_euclidean$w <- 96
mp_euclidean$ez <- 0.5
mp_euclidean$data <- list(as.matrix( df$Power_total ))
class(mp_euclidean) <- "MatrixProfile"

#FIND MOTIF ON EUCLIDEAN MP

motifs<- find_motif(
  mp_euclidean,
  n_motifs = 1,
  n_neighbors = 2,
  radius = 2,
  exclusion_zone = 1/2,
)

#FIND DISCORD ON EUCLIDEAN MP

discords<-find_discord(
  mp_euclidean,
  n_discords = 2,
  n_neighbors = 1,
  radius = 3,
  exclusion_zone = 1/2,
)

df_mp_euclidean <- as.data.frame(mp_euclidean[['mp']])

df_mp_euclidean <- df_mp_euclidean %>%
  rename(mp= V1) %>%
  mutate(X=c(1:3906))

vector_idx<-unlist(motifs[["motif"]][["motif_idx"]])
vector_idx_discord<-unlist(discords[["discord"]][["discord_idx"]])
vector_idx_nn<-unlist(discords[["discord"]][["discord_neighbor"]])


df_mp_euclidean$motifs_idx<-ifelse(df_mp_euclidean$X %in% vector_idx,1,NA)
df_mp_euclidean$discords_idx<-ifelse(df_mp_euclidean$X %in% vector_idx_discord,1,NA)
df_mp_euclidean$discords_idx_nn<-ifelse(df_mp_euclidean$X %in% vector_idx_nn,1,NA)

df_discord<-as.data.frame(c(1:nrow(df)))
df_discord$Power_total<- df$Power_total
colnames(df_discord)[1]<-'X'

df_discord$discord_position<-c(df_mp_euclidean$discords_idx,rep(NA,95))
df_discord$nn_position<-c(df_mp_euclidean$discords_idx_nn,rep(NA,95))
df_discord$Y<-ifelse(df_discord$discord_position==1,df_discord$Power_total,NA)
df_discord$Z<-ifelse(df_discord$nn_position==1,df_discord$Power_total,NA)

for (ii in c(1:4001)) {
  if(!is.na(df_discord$discord_position[ii])){
    for (jj in c(1:95)){ 
       
      df_discord$Y[ii+jj]=df_discord$Power_total[ii+jj]
      
    }
  }
  if(!is.na(df_discord$nn_position[ii])){
    for (jj in c(1:95)){ 
      
      df_discord$Z[ii+jj]=df_discord$Power_total[ii+jj]
      
    }
  }
  
}
  
# MAKE z-score MP ON TIME SERIES--------------------------------------
#data <- df$Power_total
#w<- 96 
#mp_power <- tsmp(data, window_size = w, verbose = 2)
#save(mp_power,file = './data/mp_power.Rdata')
load("./data/mp_power.RData")

# FIND MOTIF ON Z-SCORE MP

motifs_zscore<- find_motif(
  mp_power,
  n_motifs = 1,
  n_neighbors = 2,
  radius = 3,
  exclusion_zone = 1/2,
)

zscore_mp <-as.data.frame(mp_power[['mp']]) 
zscore_mp$X<- c(1:nrow(zscore_mp))
zscore_mp <- zscore_mp[,c('X','V1')]
zscore_mp <- zscore_mp %>%
  rename(mp= V1) 

vector_idx_zscore<-unlist(motifs_zscore[["motif"]][["motif_idx"]])
zscore_mp$motifs_idx<-ifelse(zscore_mp$X %in% vector_idx_zscore,1,NA)


#PLOT-------------------------------------------------------------

p_Power_total <- ggplot()+
  geom_line(data = df, aes(x=X, y=Power_total))+
  xlim(0,4001)+
  theme()

# Cleaning the first geom_line plot
p_Power_total <- p_Power_total + theme(
  axis.title.x = element_blank(),
  axis.text.x = element_blank(),
  axis.ticks.x = element_blank()
)

p_mp_zscore <- ggplot()+
  geom_line(data = zscore_mp, aes(x=X, y=mp))+
  xlim(0,4001)+
  theme()
  
  
p_mp_euclidean <- ggplot()+
  geom_line(data = df_mp_euclidean,aes(x=X,y=mp),colour='red')+
  geom_point(data= df_mp_euclidean, aes(x=X[discords_idx_nn==1], y=mp[discords_idx_nn==1]),color='blue')+
  geom_point(data= df_mp_euclidean, aes(x=X[discords_idx==1], y=mp[discords_idx==1]),color='green')+
  labs(x='X',y='mp_euclidean')+
  xlim(-1,4001)+
  theme()

p_1<-ggarrange(p_Power_total,p_mp_euclidean,p_mp_zscore, nrow = 3, ncol = 1)
annotate_figure(p_1,top = text_grob("DISCORD", color = "red", face = "bold", size = 14))
    

# DISCORD PLOT
Power_discord<-df_discord$Power_total[!is.na(df_discord$Y)][c(1:96)]
Power_discord_1<-df_discord$Power_total[!is.na(df_discord$Y)][c((96+1):(96+96))]

Power_nn<-df_discord$Power_total[!is.na(df_discord$Z)][c(1:96)]
Power_nn_1<-df_discord$Power_total[!is.na(df_discord$Z)][c((96*1+1):(96*1+96))]


dev.new()
par(mfrow=c(2,1)) 
plot(Power_discord,type = 'l')
lines(Power_nn,type = 'l', col='green')

plot(Power_discord_1,type = 'l')
lines(Power_nn_1,type = 'l', col='blue')




