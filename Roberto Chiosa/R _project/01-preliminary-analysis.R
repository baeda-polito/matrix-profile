#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

#  PREPROCESSING ------------------------------------------------------------------
# load dataset
# df <- energydataset::data_power_raw
# 
# # fix dataset names
# df_univariate <- df %>%
#   mutate(
#     CET = as.POSIXct(CET , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
#     Power_total = `1226`,
#     Power_data_centre = `1045`,
#     Power_canteen = `1047`,
#     Power_mechanical_room = `1022`,
#     Power_dimat = `294`,
#     Power_bar = `1046`,
#     Power_rectory = `1085`,
#     Power_print_shop = `1086`
#   ) %>%
#   dplyr::select(-c(2:9))
#
# save(df_univariate, file = gsub(" ", "", paste("./data/df_univariate_full.RData")))
#
# subset original dataframe 
#df_univariate <- df_univariate[c(6000:10000),]
#
# reset rownames from 1 to end
#rownames(df_univariate) <- c(6000:10000)-6000+1

# save(df_univariate, file = gsub(" ", "", paste("./data/df_univariate_small.RData")))

load("./data/df_univariate_small.RData")

# plot dataset time series
{
  p1_TS <-  plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_total",
    y_lab = "Total [kW]"
  )
  
  p2_TS <- plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_mechanical_room",
    y_lab = "Mechanical room [kW]"
  )
  
  p3_TS <-  plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_data_centre",
    y_lab = "Data Centre [kW]"
  )
  
  
  p4_TS <- plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_canteen",
    y_lab = "Canteen [kW]"
  )
  
  p5_TS <- plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_dimat",
    y_lab = "DIMAT [kW]"
  )
  
  p6_TS <- plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_bar",
    y_lab = "Bar [kW]"
  )
  
  p7_TS <- plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_rectory",
    y_lab = "Rectory [kW]"
  )
  
  p8_TS <- plot_sequence(
    type = "raw",
    df_univariate,
    x = "CET",
    x_lab = NULL,
    y = "Power_print_shop",
    y_lab = "Print Shop [kW]"
  )
  
  dev.new()
  
  ggarrange(
    p1_TS,
    p2_TS,
    p3_TS,
    p4_TS,
    p5_TS,
    p6_TS,
    p7_TS,
    p8_TS,
    ncol = 1,
    nrow = 8,
    widths = c(3),
    align = "v"
  )
  
  ggsave("./figures/01-preliminary-analysis/01-dataset.png",
         width = 10,
         height = 13)
  dev.off()
  }

#  MATRIX PROFILE ------------------------------------------------------------------
#  matrix profile on the total electrical power
variable <- "Power_total"
w = 96 # window size

# mp_univariate <- tsmp(df_univariate[[variable]], window_size = w, exclusion_zone = 0.5 )
# save(mp_univariate, file = gsub(" ", "", paste("./data/mp-", variable,"-w", w,".RData")))

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
    y_lab = "MP"
  )
  
  p2mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "rmp",
    y_lab = "RMP"
  )
  
  p3mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "lmp",
    y_lab = "LMP"
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
  
  
  ggsave(gsub(" ", "", paste("./figures/01-preliminary-analysis/02-MP-", variable,"-w", w,".png")),
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
# sequence_string <- "Discord"
# # discord index
# sequence_index <- as.numeric(discord$discord$discord_idx)


## MOOTIF DISCOVERY
motif <- find_motif(mp_univariate,
                    n_motifs = 1,
                    n_neighbors = 1
)
sequence_string <- "Motif"
# motif index
sequence_index <- as.numeric(motif$motif$motif_idx[[1]][[1]])

#  PLOTS ------------------------------------------------------------------
# first nn index
# df_mp_univariate$lmp_index[sequence_index]

# find maximum of mp r l
find_max <- as.numeric( rbind(df_mp_univariate$mp,  df_mp_univariate$rmp, df_mp_univariate$lmp) )
find_max <- find_max[find_max!= Inf]
ymax_mp <- ceiling( max(find_max ) )

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
    w = w,
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
    ymax_mp = ymax_mp,
    mp_index = "mp_index",
    w = w,
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$mp_index[sequence_index]
  )

  p2mp_discord <-  plot_sequence(
    type = "mp",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "rmp",
    y_lab = "RMP",
    ymax_mp = ymax_mp,
    mp_index = "rmp_index",
    w = w,
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$rmp_index[sequence_index]
  )

  p3mp_discord <-   plot_sequence(
    type = "mp",
    df_mp_univariate,
    x = "index",
    x_lab = NULL,
    y = "lmp",
    y_lab = "LMP",
    ymax_mp = ymax_mp,
    mp_index = "lmp_index",
    w = w,
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$lmp_index[sequence_index]
  )

  dev.new()

  fig <- ggarrange(
    p0data_discord,
    p1mp_discord,
    p2mp_discord,
    p3mp_discord,
    ncol = 1,
    nrow = 4,
    widths = c(3),
    align = "v"
  )

  annotate_figure(fig, top = text_grob(paste(sequence_string, "discovery"), color = "black", face = "bold", size = 13))
  
  ggsave( gsub(" ", "", paste("./figures/01-preliminary-analysis/03-MP-", variable,"-w", w, "-", sequence_string, ".png")),
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
    w = w,
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
    w = w,
    seq_index = sequence_index,
    seq_nn = df_mp_univariate$mp_index[sequence_index]
  )

  prmp_discord_pure <-  plot_window(
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

  prmp_discord_z <-  plot_window(
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

  plmp_discord_pure <-  plot_window(
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

  plmp_discord_z <-  plot_window(
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
    pmp_discord_pure, pmp_discord_z,
    prmp_discord_pure, prmp_discord_z,
    plmp_discord_pure, plmp_discord_z,
    ncol = 2,
    nrow = 3,
    widths = c(3,3),
    align = "v"
  )

  annotate_figure(fig,
                  top = text_grob(paste(sequence_string, "discovery window profile"), color = "black", face = "bold", size = 13),
                  left = text_grob("Power [kW]", color = "black", size = 11, rot = 90),
                  right = text_grob("Power [z-norm]", color = "black",  size = 11, rot = 90),
                  bottom = text_grob("Obs. Index", color = "black",  size = 11)

  )

  ggsave( gsub(" ", "", paste("./figures/01-preliminary-analysis/04-MP-", variable,"-w", w, "-", sequence_string, "-profile.png")),
    width = 10,
    height = 7
  )
  dev.off()
}
