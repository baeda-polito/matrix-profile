# a<- sample(1:10,30,replace = T)
# w <-5

make_AV <- function(data, subsequenceLength, type=c('motionartifact','complexity'), binary=T){
  
<<<<<<< Updated upstream
  AV = 0*c(1:length(data)-subsequenceLength+1)
  stdVector= 0*c(1:length(data)-subsequenceLength+1)
  
  for (bb in 1:(length(data)-subsequenceLength+1)){
=======
  AV = 0*c(1:(length(data)-subsequenceLength+1))
  stdVector= 0*c(1:(length(data)-subsequenceLength+1))
  
  if(type=='motionartifact'){
    
    for (bb in 1:(length(data)-subsequenceLength+1)){
      
      stdVector[bb] = sd( data[ c(bb:(bb+subsequenceLength-1)) ] )
      
    }
    meanstdV <-mean(stdVector)
>>>>>>> Stashed changes
    
    if(binary==T){
      
      AV =ifelse(stdVector >=meanstdV,0,1)
      
    }else{
      
      AV<-stdVector/max(stdVector)
      
    }
    
    return(list(AV<-AV,stdVector<-stdVector,meanstdV<-meanstdV))
  }
<<<<<<< Updated upstream
  meanstdV <- mean(stdVector)
  
  AV = ifelse(stdVector >= meanstdV,1,0)
=======
  
  if(type=='complexity'){
    
    for (bb in 1:(length(data)-subsequenceLength+1)){
      
      subsequence=data[bb:(bb+subsequenceLength-1)]
      
      AV[bb] = sqrt(sum(diff(subsequence)^2))
      
    }
    
    AV <- AV-min(AV)
    AV <- AV/max(AV) 
    
    return(AV)
    
  }
>>>>>>> Stashed changes
  
  return( list(AV = AV,
               stdVector = stdVector,
               meanstdV = meanstdV)
  )
}

<<<<<<< Updated upstream
# debug(make_AV)
# make_AV(a,w)
# 
# library(tsmp)
# ?av_complexity
# 
# data <- mp_test_data$train$data[1:1000]
# w <- 50
# 
# mp <- tsmp(data, window_size = w, verbose = 0)
# av <- av_complexity(mp, apply = TRUE)
# 
# av <- make_AV(data,w)
# 
# plot(av$AV, type = "l")
=======
debug(make_AV)
make_AV(a,w,'complexity')






>>>>>>> Stashed changes

