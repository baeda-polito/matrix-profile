#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")             # clears the console
rm(list = ls())         # remove all variables of the workspace
library(energydataset)  # energy dataset to test
library(tsmp)           # matrix profile dataset
library(dplyr)          # dataset handling
library(ggplot2)        # plot
library(ggpubr)         # arrange plots
library(ggtext)         # annotate text

source(file = "00-utils-functions.R") # load user functions

#  PREPROCESSING ------------------------------------------------------------------

# load dataset
df <- energydataset::data_power_raw

# fix dataset names
df_univariate <- df %>%
  mutate(
    CET = as.POSIXct(CET , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
    Power_total = `1226`,
    Power_data_centre = `1045`,
    Power_canteen = `1047`,
    Power_mechanical_room = `1022`,
    Power_dimat = `294`,
    Power_bar = `1046`,
    Power_rectory = `1085`,
    Power_print_shop = `1086`
  ) %>%
  dplyr::select(-c(2:9)) %>%
  # add annotation vector that favors weekdays or weekends/holyday
  mutate(
    # av = if_else(Week_day == 7 | Week_day == 8 | Holiday == TRUE, 0, 1) # AV1
    av = if_else(Week_day == 7 | Week_day == 8 | Holiday == TRUE, 1, 0) # AV2
  )



#  MATRIX PROFILE ------------------------------------------------------------------
#  matrix profile on the total electrical power
w = 96 # window size
# mp_univariate <- tsmp(df_univariate$Power_total, window_size = w, exclusion_zone = 0.5 )

# save(mp_univariate, file = "./data/mp_univariate_total_05ex_w96.RData")
load("./data/mp_univariate_total_05ex_w96.RData") # load to save time

# define length of mp
mp_length = length(mp_univariate$mp)

## Apply AV to mp
# # add annotation vector to mp list
# mp_univariate$av <- df_univariate$av[c(1:mp_length)]
# class(mp_univariate) <- tsmp:::update_class(class(mp_univariate), "AnnotationVector")
# mp_univariate <- tsmp::av_apply(mp_univariate)

# mp_annotated <- av_complexity(mp_univariate, apply = TRUE)
# av_type <- "complexity"

# mp_annotated <- av_hardlimit_artifact(mp_univariate, apply = TRUE)
# av_type <- "hardlimit_artifact"

# mp_annotated <- av_motion_artifact(mp_univariate, apply = TRUE)
# av_type <- "motion_artifact"

mp_annotated <- av_zerocrossing(mp_univariate, apply = TRUE)
av_type <- "zerocrossing"

#  ANNOTATION VECTOR: COMPLEXITY ------------------------------------------------------------------
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
  mp = mp_annotated$mp,
  mp_index = mp_annotated$pi,
  rmp = mp_annotated$rmp,
  rmp_index = mp_annotated$rpi,
  lmp = mp_annotated$lmp,
  lmp_index = mp_annotated$lpi,
  av = mp_annotated$av
)

{
  # time series plot and sequence identification
  p0data <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "data_index",
    x_lab = NULL,
    y = "data",
    y_lab = "Power [kW]"
  )
  
  p1mp_av <- plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "av",
    y_lab = "AV [-]"
  )
  
  plot(mp_annotated$av)
  
  p1mp <- plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "mp",
    y_lab = "MP",
    ymax_mp = 20,
    mp_index = "mp_index"
  )
  
  dev.new()
  
  fig <- ggarrange(
    p0data,
    p1mp_av,
    p1mp,
    ncol = 1,
    nrow = 3,
    widths = c(3),
    align = "v"
  )
  
  annotate_figure(fig, top = text_grob(paste(av_type, "discovery"), color = "black", face = "bold", size = 13))
  
  
  ggsave( gsub(" ", "", paste("./figures/01.05-total-MP-", av_type, ".png")),
          width = 10,
          height = 7)
  dev.off()
}






#  SEQUENCE DISCOVERY ------------------------------------------------------------------
#  https://matrixprofile.org/tsmp/reference/find_discord.html

# ## DISCORD DISCOVERY
# discord <- find_discord(mp_univariate,
#                         n_discords = 1,
#                         n_neighbors = 1
# )
# sequence_string <- "Discord-AV2"
# # discord index
# sequence_index <- as.numeric(discord$discord$discord_idx)


## MOOTIF DISCOVERY
motif <- find_motif(mp_univariate,
                    n_motifs = 1,
                    n_neighbors = 1
)
sequence_string <- "Motif-AV2"
# motif index
sequence_index <- as.numeric(motif$motif$motif_idx[[1]][[1]])


#  PLOTS ------------------------------------------------------------------
# first nn index
# df_mp_univariate$lmp_index[sequence_index]

# plot discord
{
  # time series plot and sequence identification
  p0data_discord <-  plot_sequence(
    type = "data",
    df_mp_univariate,
    x = "data_index",
    x_lab = NULL,
    y = "data",
    y_lab = "Power [kW]",
    w = 96,
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$mp_index[sequence_index]
  )
  
  p1mp_av <-   plot_sequence(
    type = "data",
    df_mp_univariate,
    x = "data_index",
    x_lab = NULL,
    y = "av",
    y_lab = "AV [-]",
    w = 96,
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$mp_index[sequence_index]
  )
  
  p1mp_discord <-  plot_sequence(
    type = "mp",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "mp",
    y_lab = "MP",
    ymax_mp = 20,
    mp_index = "mp_index",
    w = 96,
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$mp_index[sequence_index]
  )

  dev.new()
  
  fig <- ggarrange(
    p0data_discord,
    p1mp_av,
    p1mp_discord,
    ncol = 1,
    nrow = 3,
    widths = c(3),
    align = "v"
  )
  
  annotate_figure(fig, top = text_grob(paste(sequence_string, "discovery"), color = "black", face = "bold", size = 13))
  
  
  ggsave( gsub(" ", "", paste("./figures/01.05-total-MP-", sequence_string, ".png")),
          width = 10,
          height = 7)
  dev.off()
}

# plot discord profiles normal and normalized
{
  pmp_discord_pure <-  plot_window(
    type = "pure",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "data",
    y_lab = NULL,
    w = 96, 
    seq_index = sequence_index ,
    seq_nn =  df_mp_univariate$mp_index[sequence_index]
  )
  
  pmp_discord_z <-  plot_window(
    type = "znorm",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "data",
    y_lab = NULL,
    w = 96, 
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$mp_index[sequence_index]
  )
  
  dev.new()
  
  fig <-  ggarrange(
    pmp_discord_pure, pmp_discord_z,
    ncol = 2,
    nrow = 1,
    widths = c(3,3),
    align = "v"
  )
  
  annotate_figure(fig, 
                  top = text_grob(paste(sequence_string, "discovery window profile"), color = "black", face = "bold", size = 13),
                  left = text_grob("Power [kW]", color = "black", size = 11, rot = 90),
                  right = text_grob("Power [z-norm]", color = "black",  size = 11, rot = 90),
                  bottom = text_grob("Obs. Index", color = "black",  size = 11)
                  
  )
  
  
  ggsave(
    gsub(" ", "", paste("./figures/01.06-total-MP-", sequence_string, "-profile.png")),
    width = 10,
    height = 3
  )
  dev.off()
}


