#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

load("./data/df_univariate_full.RData")

#  VARIABLES SETTING ------------------------------------------------------------------

variable <- "Power_total"                                         # this is the timeseries used to perform the MP
w <- 96                                                           # window size # this is the window size used to compute the MP
figure_directory <- gsub(" ", "", paste("PMP-",variable ))  # this is the figure directory of this analysis
figure_path <- gsub(" ", "", paste("./figures/01-PMP/", figure_directory)) # path to figure  directory

if ( file.exists(figure_path) == FALSE ){ # directory does not exists
  dir.create( figure_path )
}


#  PAN MATRIX PROFILE ------------------------------------------------------------------

#PMP <- analyze(df_univariate[[variable]], windows = as.integer(seq(4,96*7, 2)))

#save(PMP, file = gsub(" ", "", paste("./data/pmp-", variable,".RData")))

load( gsub(" ", "", paste("./data/pmp-", variable, ".RData")) ) # load to save time


lunghezza <- NULL
nome <- NULL
for (i in 1:length(PMP$pmp)) {
  lunghezza[i] <- length(PMP$pmp[[i]])
  
}



data <- NULL
for (i in 1:length(PMP$pmp)) {
  
  tmp <- as.data.frame(PMP$pmp[[i]]) %>%
    dplyr::slice(1:min(lunghezza))
  
  colnames(tmp)[1] <- names(PMP$pmp)[i]
  
  
  tmp1 <- data.frame(
    index = as.integer(rownames(tmp)),
    w_size = nome[i],
    value = tmp[[1]]
  )
  
  data <- rbind(data,tmp1)
}


data1 <- data %>%
  dplyr::mutate(w_size = as.integer(w_size))

# Library
library(ggplot2)

# Heatmap
ggplot(data, aes(x = index, y = w_size, fill= value)) +
  geom_tile()



mp_univariate <- tsmp(df_univariate[[variable]], window_size = w, exclusion_zone = 0.5 )
save(mp_univariate, file = gsub(" ", "", paste("./data/mp-", variable,"-w", w,".RData")))

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
  rmp = mp_univariate[[3]],
  rmp_index = mp_univariate[[4]],
  lmp = mp_univariate[[5]],
  lmp_index = mp_univariate[[6]]
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
    y = "rmp",
    y_lab = paste("RMP (w",w,")")
  )
  
  p3mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "lmp",
    y_lab = paste("LMP (w",w,")")
  )
  
  dev.new()
  
  ggarrange(
    p0data,
    p1mp,
    p2mp,
    p3mp,
    ncol = 1,
    nrow = 4,
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
  
  #  PATTERNSELECTION ------------------------------------------------------------------
  if (sequence_string_vector[i] == "Discord") {
    
    # DISCORD DISCOVERY
    discord <- find_discord(mp_univariate,
                            n_discords = 1,
                            n_neighbors = 1
    )
    
    sequence_string <- sequence_string_vector[i]                # discord sting for titles
    sequence_index  <- as.numeric(discord$discord$discord_idx)  # discord index for NN
    
    
  } else if (sequence_string_vector[i] == "Motif"){
    
    ## MOOTIF DISCOVERY
    motif <- find_motif(mp_univariate,
                        n_motifs = 1,
                        n_neighbors = 1
    )
    sequence_string <- sequence_string_vector[i]                    # motif sting for titles
    sequence_index  <- as.numeric(motif$motif$motif_idx[[1]][[1]])  # motif index for NN
    
  }
  
  #  PLOTS ------------------------------------------------------------------
  # find maximum of mp r l to scale the plots
  find_max <- as.numeric( rbind(df_mp_univariate$mp,  df_mp_univariate$rmp, df_mp_univariate$lmp) )
  find_max <- find_max[find_max!= Inf]
  ymax_mp <- ceiling( max(find_max ) )
  
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
    
    p2mp_pattern <-  plot_sequence(
      type = "mp",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "rmp",
      y_lab = paste("RMP - w",w),
      ymax_mp = ymax_mp,
      mp_index = "rmp_index",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$rmp_index[sequence_index],
      annotate_mp = TRUE
    )
    
    p3mp_pattern <-   plot_sequence(
      type = "mp",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "lmp",
      y_lab = paste("LMP - w",w),
      ymax_mp = ymax_mp,
      mp_index = "lmp_index",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$lmp_index[sequence_index],
      annotate_mp = TRUE
    )
    
    dev.new()
    
    fig <- ggarrange(
      p0data_pattern,
      p1mp_pattern,
      p2mp_pattern,
      p3mp_pattern,
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
    
    prmp_pattern_pure <-  plot_window(
      type = "pure",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index ,
      seq_nn =  df_mp_univariate$rmp_index[sequence_index]
    )
    
    prmp_pattern_z <-  plot_window(
      type = "znorm",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$rmp_index[sequence_index]
    )
    
    plmp_pattern_pure <-  plot_window(
      type = "pure",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index ,
      seq_nn =  df_mp_univariate$lmp_index[sequence_index]
    )
    
    plmp_pattern_z <-  plot_window(
      type = "znorm",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$lmp_index[sequence_index]
    )
    
    dev.new()
    
    fig <-  ggarrange(
      pmp_pattern_pure, pmp_pattern_z,
      prmp_pattern_pure, prmp_pattern_z,
      plmp_pattern_pure, plmp_pattern_z,
      ncol = 2,
      nrow = 3,
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






