a<- sample(1:10,30,replace = T)
w <-5

make_AV <- function(data, subsequenceLength){
  
  AV = 0*c(1:length(data)-subsequenceLength+1)
  stdVector= 0*c(1:length(data)-subsequenceLength+1)

  for (bb in 1:(length(data)-subsequenceLength+1)){
    
    stdVector[bb] = sd( data[ c(bb:(bb+subsequenceLength-1)) ] )
    
  }
  meanstdV <-mean(stdVector)
  
  AV =ifelse(stdVector >=meanstdV,1,0)
  
 
  return(list(AV,stdVector,meanstdV))


  
}

debug(make_AV)
make_AV(a,w)






                    
                    
                    
       