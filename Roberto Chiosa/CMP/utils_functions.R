library(stringr)

# str <- "00:00"
# hour_to_dec(str)

hour_to_dec <- function(str){
 
  str <- as.list(str)  # convert input into string
  string_splitted <- str_split(str, ":") # split string into hour minute second
  
  # initializa loop variables
  lunghezza <- length(str)
  hour <- seq(lunghezza)*0
  minute <- seq(lunghezza)*0
  
  # for each entry of the string extractvalues
  for (i in 1:length(str)) {
    hour[i] <- as.numeric( string_splitted[[i]][1])
    minute[i] <- as.numeric( string_splitted[[i]][2])/60
  }
  
  return(hour+minute)
}


dec_to_hour <- function(min_dec){
  hour <- floor(min_dec)
  minute <- (min_dec - floor(min_dec))*60
  return(sprintf("%02d:%02d", hour, minute))
}