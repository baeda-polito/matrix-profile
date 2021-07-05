library(ggplot2)  



#' @name make_AV
#' 
#' @title Normalizes data between Zero and One
#' see https://github.com/matrix-profile-foundation/tsmp/blob/a1f2937bd3a3a83a0d23df601b4ed686dabbc96b/R/misc.R
#' @param data a `vector` or a column `matrix` of `numeric`.
#'
#' @return Returns the normalized data.
#' @keywords internal
#' @noRd
#'
zero_one_norm <- function(data) {
  data <- round(data, 10)
  
  data <- data - min(data[!is.infinite(data) & !is.na(data)])
  data <- data / max(data[!is.infinite(data) & !is.na(data)])
  
  return(data)
}

#' @name make_AV
#' 
#' @title Make Custom Annotation Vectors
#' 
#' @description 
#' This function permits to create cystom annotation vector
#' 
#' @param data a vector of data (time series) of which the annotation vector has to be constructed
#' @param subsequenceLength width of the moving window
#' @param type type of annotation vector to be created. Available type are \code{complexity} \code{motion_artifact}
#' @param binary

make_AV_explore <- function(data, subsequenceLength, type = c('motion_artifact','complexity'), binary = TRUE){
  
  # initialize function based variables
  AV <- NULL
  stdVector <-  NULL
  
  if (type == 'motion_artifact'){
    
    # proceed to calculate AV with moving window
    for (bb in 1:(length(data)-subsequenceLength+1) ){
      
      # calculates standard deviation
      stdVector[bb] <- sd( data[c(bb:(bb+subsequenceLength-1))] )
      
      
    }
    
    if(binary == TRUE){
      # returns a binary {0,1} annotation vector
      AV <- ifelse(stdVector >= mean(stdVector), 0, 1)
      l<-list(AV,stdVector,mean(stdVector))
      return(l)
      } 
  
    else if(binary == FALSE){
      # returns a real valued {0,1} annotation vector
      # AV <- stdVector/max(stdVector) 
      AV <- zero_one_norm(stdVector)
      l<-list(AV,stdVector,mean(stdVector))
      return(l)
    }
    else {
      warning("ERROR 'binary' must be {TRUE,FALSE}")
      return()
    }
    
  }
  else if (type == 'complexity'){
    
    # proceed to calculate AV with moving window
    for (bb in 1:(length(data) - subsequenceLength + 1) ){
      
      subsequence <- data[ bb:(bb+subsequenceLength-1) ]
      
      AV[bb] <- sqrt( sum( diff(subsequence)^2 ) )
    }
    
    AV <- zero_one_norm(AV)
    l<-list(AV,stdVector)
    return(l)
  }
  else {
    warning("ERROR 'type' must be one of {'motion_artifact','complexity'} ")
    return()
  }
  
}



# explore make AV function to understand # 07/06/2021
w_AV_make<-4
MAB<- make_AV_explore(df_time_series$leaf_node_3,w_AV_make,'motion_artifact',T)

dev.new()
png(file="./grafici/explore_AV_make.png")
par(mfrow=c(3,1))
plot(MAB[[1]],type = 'l')
plot(MAB[[2]],type = 'l')
plot(MAB[[3]]*rep(1,length(MAB[[2]])),type = 'l')
dev.off()


#debug(make_AV)
#make_AV(aaa,96,'motion_artifact',T)


## example for debug
#library(tsmp)

# to make comparison we use tsmp builtin datasets
#data <- mp_test_data$train$data[1:1000]
#w <- 50

#############  tsmp complexity vs custom
#mp <- tsmp(data, window_size = w, verbose = 0)
#av <- av_complexity(mp, apply = TRUE)
#plot(av$av, type = "l")

# debug(make_AV)
#av_new <- make_AV( data = data, subsequenceLength = w, type = 'complexity')
#plot(av_new, type = "l")

############# tsmp motion_artifact vs custom
#mp <- tsmp(data, window_size = w, verbose = 0)
#av <- av_motion_artifact(mp, apply = TRUE)
#plot(av$av, type = "l")

# debug(make_AV)
#av_new <- make_AV( data = data, subsequenceLength = w, type = 'motion_artifact', binary = TRUE)
#plot(av_new, type = "l")