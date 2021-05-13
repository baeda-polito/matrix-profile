library(lubridate)
library(rpart)
library(partykit)
library(MLmetrics)
library(magrittr)
library(plyr)
library(dplyr)
library(tidyr)
library(scales)
library(imputeTS)
library(RColorBrewer)
library(NbClust)
library(ggplot2)
library(ggpubr)
library(factoextra)
library(dendextend)
library(ggparty)
library(tsmp)
library(plotrix)

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
 
 p3 <- p1+
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


#A.V

av=0*c(1:nrow(df))

for(ii in c(1:nrow(df))){
  
  if(df$Month_day[ii]!=6 & df$Month_day[ii]!=7){
    
    av[ii]=1
  }
}

annotation_vector <-av_zerocrossing(mp, av, apply = TRUE)

motif_subseq_annotation<-motifs(
  annotation_vector,
  exclusion_zone = 1/2,
  k = 4,
  neighbor_count = 3,
  radius = 4
)


dev.new()
plot(motif_subseq_annotation)





