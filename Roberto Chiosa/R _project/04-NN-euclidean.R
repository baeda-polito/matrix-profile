#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

#  VARIABLES SETTING ------------------------------------------------------------------
load("./data/df_univariate_small.RData")

variable <- "Power_total"                                         # this is the timeseries used to perform the MP
w <- 96                                                           # window size # this is the window size used to compute the MP
figure_directory <- gsub(" ", "", paste("MP-",variable,"-w",w , "-euclidean"))  # this is the figure directory of this analysis


figure_path <- gsub(" ", "", paste("./figures/04-NN-euclidean/", figure_directory)) # path to figure  directory

if ( file.exists(figure_path) == FALSE ){ # directory does not exists
  dir.create( figure_path )
}

#  MATRIX PROFILE ------------------------------------------------------------------

mp_euclidean <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/mp_euclidean.csv",
                         col.names = c("row","mp", "pi", "lpi", "rpi")) %>%
  dplyr::mutate(row = row-1)

# mp_euclidean$row <- NULL
# mp_euclidean <- as.list(mp_euclidean)
# mp_euclidean$mp <- as.matrix(mp_euclidean$mp)
# mp_euclidean$pi <- as.matrix(mp_euclidean$pi)
# mp_euclidean$lpi <- as.matrix(mp_euclidean$lpi)
# mp_euclidean$rpi <- as.matrix(mp_euclidean$rpi)
# 
# mp_euclidean$w <- 96
# mp_euclidean$ez <- 0.5
# mp_euclidean$data <- list(as.matrix( df_univariate$Power_total ))
# 
# class(mp_euclidean) <- "MatrixProfile"
# 
# find_motif(mp_euclidean, n_motifs = 1)
# 
# class(mp_univariate)

load( gsub(" ", "", paste("./data/mp-", variable,"-w", w,".RData")) ) # load to save time


# define length of mp
mp_length = length(mp_univariate$mp)

df_mp_univariate <- data.frame(
  year = df_univariate$Year[c(1:mp_length)],
  month = df_univariate$Month[c(1:mp_length)],
  day = df_univariate$Week_day[c(1:mp_length)],
  hour = df_univariate$Hour[c(1:mp_length)],
  time = df_univariate$Time[c(1:mp_length)],
  holiday = df_univariate$Holiday[c(1:mp_length)],
  tou = df_univariate$ToU[c(1:mp_length)],
  year = df_univariate$Year[c(1:mp_length)],
  data = df_univariate$Power_total[c(1:mp_length)],
  data_index = df_univariate$CET[c(1:mp_length)],
  index = as.integer(rownames(df_univariate)[c(1:mp_length)]),
  mp = mp_univariate[[1]],
  mp_index = mp_univariate[[2]],
  mp_euclidean = mp_euclidean$mp,
  mp_euclidean_index = mp_euclidean$pi
)
head(df_mp_univariate)

############# 
# validation of nn search

w <- mp_toy_data$sub_len
ref_data <- mp_toy_data$data[, 1]
# minimum example, data and query
nn <- dist_profile(ref_data, ref_data[1:w])
distance_profile <- sqrt(nn$distance_profile)

# Classical MDS
# N rows (objects) x p columns (variables)
# each row identified by a unique row name

d <- dist(mp_univariate$mp[0:1000]) # euclidean distances between the rows
fit <- cmdscale(d,eig=TRUE, k=2) # k is the number of dim
#fit # view results

# plot solution
x <- fit$points[,1]
y <- fit$points[,2]
plot(x, y, xlab="Coordinate 1", ylab="Coordinate 2",
     main="Metric MDS")
text(x, y, labels = row.names(mydata), cex=.7)



find_discord(mp_univariate,
             n_discords = 1,
             n_neighbors = 3
             #radius = 3,
             #exclusion_zone = NULL,
             )

# maximum of MP ie discord
max(mp_univariate$mp)
# discord index
which( mp_univariate$mp == max(mp_univariate$mp) )
# 1st NN
mp_univariate$pi[ mp_univariate$mp == max(mp_univariate$mp) ]

# find 2nd NN
mp_univariate$mp[ which( mp_univariate$mp == max(mp_univariate$mp) ) ] <- NULL
# maximum of MP ie discord
max(mp_univariate$mp)
# discord index
which( mp_univariate$mp == max(mp_univariate$mp) )
# 1st NN
mp_univariate$pi[ mp_univariate$mp == max(mp_univariate$mp) ]


mp_univariate$pi[ mp_univariate$mp == max(mp_univariate$mp) ]


#############
diff <- NULL
w <- 96
for (j in 1:length(mp_euclidean$mp)) {

  
  # # index of this sequence
  # df_mp_univariate$index[j]
  # 
  # # index of nearest neighbor
  # df_mp_univariate$mp_euclidean_index[1]
  
  # profile
  
  actual_index <- j
  prof1 <- mp_euclidean$mp[actual_index:(actual_index+w)]
  energy_prof1 <- last(cumsum(prof1))-first(cumsum(prof1))
    
    
  NN1_index <- mp_euclidean$pi[actual_index]
  prof2 <- mp_euclidean$pi[NN1_index:(NN1_index+w)]
  energy_prof2 <- last(cumsum(prof2))-first(cumsum(prof2))
  
  diff[j] <- energy_prof1 - energy_prof2
  
  # plot(df_mp_univariate$mp_euclidean[1:96], type = "l")
  # plot(cumsum(df_mp_univariate$mp_euclidean[1:96]), type = "l")
  # 
  # df_mp_univariate$mp_euclidean_index[576]
  # plot(df_mp_univariate$mp_euclidean[576:(576+96)], type = "l")
  # 
  # plot(cumsum(df_mp_univariate$mp_euclidean[576:(576+96)]), type = "l")
  # 
  # 
  # df_mp_univariate$mp_euclidean_index[1346]
  
}

df_mp_univariate$diff <- diff
  

p1mp <-  plot_sequence(
  type = "raw",
  df_mp_univariate,
  x = "index",
  x_lab = NULL,
  y = "mp_euclidean"
)

p2mp <-  plot_sequence(
  type = "raw",
  df_mp_univariate,
  x = "index",
  x_lab = NULL,
  y = "diff"
)

dev.new()

ggarrange(

  p1mp,
  p2mp,
  ncol = 1,
  nrow = 2,
  widths = c(3),
  align = "v"
)


ggsave(gsub(" ", "", paste(figure_path, "/1-MP.png")),
       width = 10,
       height = 7)
dev.off()


plot(diff, type = "l")


#############


custom_search(mp_univariate, 
              INDEXX = 359,
             n_discords = 1,
             n_neighbors = 3)

INDEX_CUSTOM = 359


custom_search <- function(.mp, data, INDEXX, n_discords = 1, n_neighbors = 3, radius = 3, exclusion_zone = NULL, ...) {
  if (!("MatrixProfile" %in% class(.mp))) {
    stop("First argument must be an object of class `MatrixProfile`.")
  }
  
  if ("Valmod" %in% class(.mp)) {
    stop("Function not implemented for objects of class `Valmod`.")
  }
  
  if (missing(data) && !is.null(.mp$data)) {
    data <- .mp$data[[1]]
  }
  
  # transform data list into matrix
  if (is.matrix(data) || is.data.frame(data)) {
    if (is.data.frame(data)) {
      data <- as.matrix(data)
    } # just to be uniform
    if (ncol(data) > nrow(data)) {
      data <- t(data)
    }
    data_len <- nrow(data)
    data_dim <- ncol(data)
  } else if (is.list(data)) {
    data_len <- length(data[[1]])
    data_dim <- length(data)
    
    for (i in 1L:data_dim) {
      len <- length(data[[i]])
      # Fix TS size with NaN
      if (len < data_len) {
        data[[i]] <- c(data[[i]], rep(NA, data_len - len))
      }
    }
    # transform data into matrix (each column is a TS)
    data <- sapply(data, cbind)
  } else if (is.vector(data)) {
    data_len <- length(data)
    data_dim <- 1
    # transform data into 1-col matrix
    data <- as.matrix(data) # just to be uniform
  } else {
    stop("`data` must be `matrix`, `data.frame`, `vector` or `list`.")
  }
  
  matrix_profile <- .mp$mp # keep mp intact
  matrix_profile_size <- length(matrix_profile)
  discord_idxs <- list(discords = list(NULL), neighbors = list(NULL))
  
  if (is.null(exclusion_zone)) {
    exclusion_zone <- .mp$ez
  }
  
  exclusion_zone <- round(.mp$w * exclusion_zone + vars()$eps)
  
  nn <- NULL
  
  for (i in seq_len(n_discords)) {
    discord_idx <- INDEXX
    #discord_idx <- which.max(matrix_profile)
    discord_distance <- matrix_profile[discord_idx]
    discord_idxs[[1L]][[i]] <- discord_idx
    
    # query using the discord to find its neighbors
    nn <- dist_profile(data, data, nn, window_size = .mp$w, index = discord_idx)
    
    distance_profile <- nn$distance_profile
    distance_profile[distance_profile > (discord_distance * radius)^2] <- Inf
    discord_zone_start <- max(1, discord_idx - exclusion_zone)
    discord_zone_end <- min(matrix_profile_size, discord_idx + exclusion_zone)
    distance_profile[discord_zone_start:discord_zone_end] <- Inf
    st <- sort(distance_profile, index.return = TRUE)
    distance_order <- st$x
    distance_idx_order <- st$ix
    
    discord_neighbor <- vector(mode = "numeric")
    
    for (j in seq_len(n_neighbors)) {
      if (is.infinite(distance_order[1]) || length(distance_order) < j) {
        break
      }
      discord_neighbor[j] <- distance_idx_order[1L]
      distance_order <- distance_order[2:length(distance_order)]
      distance_idx_order <- distance_idx_order[2L:length(distance_idx_order)]
      distance_order <- distance_order[!(abs(distance_idx_order - discord_neighbor[j]) < exclusion_zone)]
      distance_idx_order <- distance_idx_order[!(abs(distance_idx_order - discord_neighbor[j]) < exclusion_zone)]
    }
    
    discord_neighbor <- discord_neighbor[discord_neighbor != 0]
    discord_idxs[[2]][[i]] <- discord_neighbor
    
    remove_idx <- c(discord_idxs[[1]][[i]], discord_idxs[[2]][[i]])
    
    for (j in seq_len(length(remove_idx))) {
      remove_zone_start <- max(1, remove_idx[j] - exclusion_zone)
      remove_zone_end <- min(matrix_profile_size, remove_idx[j] + exclusion_zone)
      matrix_profile[remove_zone_start:remove_zone_end] <- -Inf
    }
  }
  
  .mp$discord <- list(discord_idx = discord_idxs[[1]], discord_neighbor = discord_idxs[[2]])
  class(.mp) <- update_class(class(.mp), "Discord")
  return(.mp)
}



