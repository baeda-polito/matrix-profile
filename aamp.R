aamp <- function(data, window_size) {
  data_size <- length(data)
  s <- data_size - window_size
  matrix_profile <- rep(Inf, s)
  profile_index <- rep(-1, s)
  
  for (k in seq_len(s - 1)) {
    dist <- sum((data[1:window_size] - data[(k + 1):(k + window_size)])^2)
    
    if (dist < matrix_profile[1]) {
      matrix_profile[1] <- dist
      profile_index[1] <- k
    }
    
    if (dist < matrix_profile[k]) {
      matrix_profile[k] <- dist
      profile_index[k] <- 1
    }
    
    for (i in seq_len(s - k)) {
      kplusi <- k + i
      
      dist <- dist - (data[i] - data[kplusi])^2 + (data[window_size + i] - data[window_size + kplusi])^2
      
      if (matrix_profile[i] > dist) {
        matrix_profile[i] <- dist
        profile_index[i] <- kplusi
      }
      
      if (matrix_profile[kplusi] > dist) {
        matrix_profile[kplusi] <- dist
        profile_index[kplusi] <- i
      }
    }
  }
  
  matrix_profile <- sqrt(matrix_profile)
  return(list(mp = matrix_profile, pi = profile_index))
}

