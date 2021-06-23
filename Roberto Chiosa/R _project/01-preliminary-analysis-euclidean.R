#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

#  VARIABLES SETTING ------------------------------------------------------------------
load("./data/df_univariate_small.RData")

variable <- "Power_total"                                         # this is the timeseries used to perform the MP
w <- 96                                                           # window size # this is the window size used to compute the MP
figure_directory <- gsub(" ", "", paste("MP-",variable,"-w",w , "-euclidean"))  # this is the figure directory of this analysis
figure_path <- gsub(" ", "", paste("./figures/01-preliminary-analysis-euclidean/", figure_directory)) # path to figure  directory

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

# plot matrix profile
{
  mplimity <- 15
  
  
  p0data <- plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "data_index",
    x_lab = NULL,
    y = "data",
    y_lab = "Total [kW]"
  )
  
  p1mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "mp",
    y_lab = paste("MP (w",w,")")
  )
  
  p2mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "mp_euclidean",
    y_lab = paste("euclidean MP (w",w,")")
  )
  
  
  dev.new()
  
  ggarrange(
    p0data,
    p1mp,
    p2mp,
    ncol = 1,
    nrow = 3,
    widths = c(3),
    align = "v"
  )
  
  
  ggsave(gsub(" ", "", paste(figure_path, "/1-MP.png")),
         width = 10,
         height = 7)
  dev.off()
  
}

#  SEQUENCE DISCOVERY ------------------------------------------------------------------
#  https://matrixprofile.org/tsmp/reference/find_discord.html

sequence_string_vector <- c("Motif", "Discord")

for (i in 1:length(sequence_string_vector)) {
  
  #  PATTERN SELECTION ------------------------------------------------------------------
  if (sequence_string_vector[i] == "Discord") {
    
    # DISCORD DISCOVERY
    discord <- find_discord(mp_univariate,
                            n_discords = 1,
                            n_neighbors = 1
    )
    
    sequence_string <- sequence_string_vector[i]                # discord sting for titles
    sequence_index  <- as.numeric(discord$discord$discord_idx)  # discord index for NN

    sequence_index_euclidean <- which( mp_euclidean$mp == max(mp_euclidean$mp), arr.ind=TRUE)
    
  } else if (sequence_string_vector[i] == "Motif"){
    
    ## MOOTIF DISCOVERY
    motif <- find_motif(mp_univariate,
                        n_motifs = 1,
                        n_neighbors = 1
    )
    sequence_string <- sequence_string_vector[i]                    # motif sting for titles
    sequence_index  <- as.numeric(motif$motif$motif_idx[[1]][[1]])  # motif index for NN
    
    sequence_index_euclidean <- which( mp_euclidean$mp == min(mp_euclidean$mp), arr.ind=TRUE)[1]
  }
  
  #  PLOTS ------------------------------------------------------------------
  # find maximum of mp r l to scale the plots
  find_max <- as.numeric( rbind(df_mp_univariate$mp,  df_mp_univariate$rmp, df_mp_univariate$lmp) )
  find_max <- find_max[find_max!= Inf]
  ymax_mp <- ceiling( max(find_max ) )
  
  find_max_euclidean <- as.numeric( rbind(mp_euclidean$mp) )
  find_max_euclidean <- find_max_euclidean[find_max_euclidean!= Inf]
  ymax_mp_euclidean <- ceiling( max(find_max_euclidean ) )
  
  # plot matrix profile with subsequences
  {
    # time series plot and sequence identification
    p0data_pattern <-  plot_sequence(
      type = "data",
      df_mp_univariate,
      x = "data_index",
      x_lab = NULL,
      y = "data",
      y_lab = "Power [kW]",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_index[sequence_index]
    )
    
    p1mp_pattern <-  plot_sequence(
      type = "mp",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "mp",
      y_lab = paste("MP - w",w),
      ymax_mp = ymax_mp,
      mp_index = "mp_index",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_index[sequence_index],
      annotate_mp = TRUE
    )
    
    # time series plot and sequence identification
    p0data_pattern_euclidean <-  plot_sequence(
      type = "data",
      df_mp_univariate,
      x = "data_index",
      x_lab = NULL,
      y = "data",
      y_lab = "Power [kW]",
      w = w,
      seq_index = sequence_index_euclidean,
      seq_nn = df_mp_univariate$mp_euclidean_index[sequence_index_euclidean],
    )
    
    p1mp_pattern_euclidean <-  plot_sequence(
      type = "mp",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "mp_euclidean",
      y_lab = paste("euclidean MP - w",w),
      ymax_mp = ymax_mp_euclidean,
      mp_index = "mp_euclidean_index",
      w = w,
      seq_index = sequence_index_euclidean,
      seq_nn = df_mp_univariate$mp_euclidean_index[sequence_index_euclidean],
      annotate_mp = TRUE
    )
    
    
    dev.new()
    
    fig <- ggarrange(
      p0data_pattern,
      p1mp_pattern,
      p0data_pattern_euclidean,
      p1mp_pattern_euclidean,
      ncol = 1,
      nrow = 4,
      widths = c(3),
      align = "v"
    )
    
    annotate_figure(fig, top = text_grob(paste(sequence_string, "discovery"), color = "black", face = "bold", size = 13))
    
    ggsave( gsub(" ", "", paste(figure_path ,"/2-", sequence_string, "-mp.png")),
            width = 10,
            height = 7)
    dev.off()
  }
  
  # plot pattern profiles normal and normalized
  {
    pmp_pattern_pure <-  plot_window(
      type = "pure",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index ,
      seq_nn =  df_mp_univariate$mp_index[sequence_index]
    )
    
    pmp_pattern_z <-  plot_window(
      type = "znorm",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_index[sequence_index]
    )
    
    
    pmp_pattern_pure_euclidean <-  plot_window(
      type = "pure",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index_euclidean,
      seq_nn = df_mp_univariate$mp_euclidean_index[sequence_index_euclidean],
    )
    
    pmp_pattern_z_euclidean <-  plot_window(
      type = "znorm",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index_euclidean,
      seq_nn = df_mp_univariate$mp_euclidean_index[sequence_index_euclidean],
    )
    
    
    dev.new()
    
    fig <-  ggarrange(
      pmp_pattern_pure, pmp_pattern_z,
      pmp_pattern_pure_euclidean, pmp_pattern_z_euclidean,
      ncol = 2,
      nrow = 2,
      widths = c(3,3),
      align = "v"
    )
    
    annotate_figure(fig,
                    top = text_grob(paste(sequence_string, "Profile - w", w), color = "black", face = "bold", size = 13),
                    left = text_grob("Power [kW]", color = "black", size = 11, rot = 90),
                    right = text_grob("Power [z-norm]", color = "black",  size = 11, rot = 90),
                    bottom = text_grob("Obs. Index", color = "black",  size = 11)
                    
    )
    ggsave( gsub(" ", "", paste(figure_path ,"/2-", sequence_string, "-profile.png")),
            width = 10,
            height = 7
    )
    dev.off()
  }
  
}






