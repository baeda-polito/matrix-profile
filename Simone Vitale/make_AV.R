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

make_AV <- function(data, subsequenceLength, type = c('motion_artifact','complexity'), binary = TRUE){
  
  # initialize function based variables
  AV <- NULL
  stdVector <-  NULL
  
  if (type == 'motion_artifact'){
    
    # proceed to calculate AV with moving window
    for (bb in 1:(length(data)-subsequenceLength+1) ){
      
      # calculates standard deviation
      stdVector[bb] <- sd( data[ c(bb:(bb+subsequenceLength-1)) ] )
      
    }
    
    if(binary == TRUE){
      # returns a binary {0,1} annotation vector
      AV <- ifelse(stdVector >= mean(stdVector), 0, 1)
      return(AV)
    } 
    else if(binary == FALSE){
      # returns a real valued {0,1} annotation vector
      # AV <- stdVector/max(stdVector) 
      AV <- zero_one_norm(AV)
      return(AV)
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

    return(AV)
  }
  else {
    warning("ERROR 'type' must be one of {'motion_artifact','complexity'} ")
    return()
  }
  
}


#debug(make_AV)
#make_AV(aa,672,'motion_artifact',F)





## example for debug
library(tsmp)

# to make comparison we use tsmp builtin datasets
data <- mp_test_data$train$data[1:1000]
w <- 50

#############  tsmp complexity vs custom
mp <- tsmp(data, window_size = w, verbose = 0)
av <- av_complexity(mp, apply = TRUE)
plot(av$av, type = "l")

# debug(make_AV)
av_new <- make_AV( data = data, subsequenceLength = w, type = 'complexity')
plot(av_new, type = "l")

############# tsmp motion_artifact vs custom
mp <- tsmp(data, window_size = w, verbose = 0)
av <- av_motion_artifact(mp, apply = TRUE)
plot(av$av, type = "l")

# debug(make_AV)
av_new <- make_AV( data = data, subsequenceLength = w, type = 'motion_artifact', binary = TRUE)
plot(av_new, type = "l")



