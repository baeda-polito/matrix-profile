# naive computation of matrix profile
# 

library(tsmp)
TS = c(0,1,3,2,9,1,14,15,1,2,2,10,7)

T1 = c(0,1,3,2)
m = 4

for (i in 1:(length(TS)-m+1) ) {
  T2 <-  TS[i:(i+m-1)]
  
  T1n = (T1-mean(T1))/sd(T1)
  T2n = (T2-mean(T2))/sd(T2)
  
  distance <- dist(rbind(T1n,T2n))
  print(paste("Sequence", i))
  print(distance)
}

  T2 = c(2,2,10,7)


mp <- tsmp::tsmp(TS, window_size = 4)

mp$mp

matrix(T1, T2)

dist(rbind(T1,T2))

