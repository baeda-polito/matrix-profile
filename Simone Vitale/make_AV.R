 a<- sample(1:10,30,replace = T)
 w <-5

make_AV <- function(data, subsequenceLength, type=c('motionartifact','complexity'), binary=T){
  
  
  AV = 0*c(1:length(data)-subsequenceLength+1)
  stdVector= 0*c(1:length(data)-subsequenceLength+1)
  
  for (bb in 1:(length(data)-subsequenceLength+1)){
    
    AV = 0*c(1:(length(data)-subsequenceLength+1))
    stdVector= 0*c(1:(length(data)-subsequenceLength+1))
    
    if(type=='motionartifact'){
      
      for (bb in 1:(length(data)-subsequenceLength+1)){
        
        stdVector[bb] = sd( data[ c(bb:(bb+subsequenceLength-1)) ] )
        
      }
      meanstdV <-mean(stdVector)
      
      
      if(binary==T){
        
        AV =ifelse(stdVector >=meanstdV,0,1)
        
      }else{
        
        AV<-stdVector/max(stdVector)
        
      }
      
      return(list(AV<-AV,stdVector<-stdVector,meanstdV<-meanstdV))
    }
    
    meanstdV <- mean(stdVector)
    
    AV = ifelse(stdVector >= meanstdV,1,0)
    
    
    if(type=='complexity'){
      
      for (bb in 1:(length(data)-subsequenceLength+1)){
        
        subsequence=data[bb:(bb+subsequenceLength-1)]
        
        AV[bb] = sqrt(sum(diff(subsequence)^2))
        
      }
      
      AV <- AV-min(AV)
      AV <- AV/max(AV) 
      
      return(AV)
      
    }
    
  }
}

debug(make_AV)
make_AV(a,w,'complexity')




