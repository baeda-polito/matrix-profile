make_AV <- function(data, subsequenceLength){
  
  AV=0*c(1:length(data)-subsequenceLength+1)
  
  for (ii in 1:length(data)-subsequenceLength+1){
    
    stdVector[ii]=sd(data[ii:ii+subsequenceLength-1])
    
  }
  
 AV(stdVector >= mean(stdVector))=0 
 AV(stdVector < mean(stdVector))=1 
 
 return(AV)
  
}

                    
                    
                    
       