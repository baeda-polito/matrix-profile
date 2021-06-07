#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

load( "./data/df_univariate_small.RData" ) # load to save time
w = 96 # window size

# !!!!!!!!!!!!!!
# to make the AV we can use a custom timeseries, not only the original timeseries

# define different ts on which we want to construct the annotation vector

actual_ts <-c(
  "Power_total"          ,
  "Power_data_centre"    ,
  "Power_canteen"        ,
  "Power_mechanical_room",
  "Power_dimat"          ,
  "Power_bar"            ,
  "Power_rectory"        ,
  "Power_print_shop" 
)

ifelse(!dir.exists(file.path(mainDir, subDir)), dir.create(file.path(mainDir, subDir)), FALSE)

for (i in 1:length(actual_ts)) {
  
  rm(df_mp_univariate, mp_univariate, discord, sequence_index)

  
  load("./data/mp-Power_total-w96.RData") # load to save time
  
  # define length of mp
  mp_length = length(mp_univariate$mp)
  
  # creates dataframe for plot
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
    mp_original = mp_univariate$mp[,1],
    mp_original_index = mp_univariate$pi[,1]
  )
  
  
  ts_for_AV_name <- actual_ts[i] # name of the av we are working on
  ts_for_AV <-  as.numeric(df_univariate[[ts_for_AV_name]]) # vector of the av we are working on
  
  # save the av in the matrix profile generated
  mp_univariate$av <-  make_AV( data = ts_for_AV, subsequenceLength = w, type = 'motion_artifact', binary = TRUE, debug_mode = TRUE)$AV[c(1:mp_length)]
  # save the std vector as well
  mp_univariate$stdVector <-  make_AV( data = ts_for_AV, subsequenceLength = w, type = 'motion_artifact', binary = TRUE, debug_mode = TRUE)$stdVector[c(1:mp_length)]
  # change class in order to be consistent
  class(mp_univariate) <-tsmp:::update_class(class(mp_univariate), "AnnotationVector")
  # apply and correct matrix profile
  mp_annotated <- tsmp::av_apply(mp_univariate)

  # adds annotated results of mp
  df_mp_univariate$mp_annotated <- mp_annotated$mp[,1]
  df_mp_univariate$mp_annotated_index <- mp_annotated$pi[,1]
  df_mp_univariate$av <- mp_annotated$av
  df_mp_univariate$stdVector <- mp_annotated$stdVector
  df_mp_univariate$mean_stdVector <- rep( mean(mp_annotated$stdVector), length(mp_annotated$stdVector))
  
  
  # find maximum of mp r l
  find_max <- as.numeric( rbind(df_mp_univariate$mp_original,  df_mp_univariate$mp_annotated) )
  find_max <- find_max[find_max!= Inf]
  ymax_mp <- ceiling( max(find_max ) )
  
  
  # plot timeseries
  {
    
    ## DISCORD DISCOVERY on original MP
    discord <- find_discord(mp_univariate,
                            n_discords = 1,
                            n_neighbors = 1
    )
    sequence_string <- "Discord"
    # discord index
    sequence_index <- as.numeric(discord$discord$discord_idx)
    
    
    p0data <-  plot_sequence(
      type = "data",
      dataset = df_mp_univariate,
      x = "data_index",
      x_lab = NULL,
      y = "data",
      y_lab = "Total Power [kW]",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_original_index[sequence_index]
    )
  
    p1mp_old <-  plot_sequence(
      type = "mp",
      dataset = df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "mp_original",
      y_lab = "MP original",
      ymax_mp = ymax_mp,
      mp_index = "mp_original_index",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_original_index[sequence_index]
    )
    
    # scale coefficient for second axes 
    coeff =  max(ts_for_AV[c(1: (length(ts_for_AV)-w+1)) ])/ max(df_mp_univariate$stdVector)
    
    # plot of std vector mean and ts for av in debug mode
    p2mp_av_debug <- ggplot(df_mp_univariate) +
      geom_line( aes_string(x = "index", y = "stdVector"),  color = "red") +
      geom_line( aes_string(x = "index", y = "mean_stdVector"),  color = "green") +
      geom_line( aes(x = index, y = ts_for_AV[c(1: (length(ts_for_AV)-w+1)) ] /coeff),  color = "gray") +
      scale_y_continuous(
        # Add a second axis and specify its features
        sec.axis = sec_axis(~.*coeff)
      )+
      theme_classic() +
      theme(
        plot.title = element_markdown(lineheight = 1.1),
        panel.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        
        legend.title = element_text(size = 11),
        axis.title.x = element_text(
          size = 11,
          margin = margin(
            t = 1,
            r = 1,
            b = 0,
            l = 0,
            unit = "mm"
          )
        ),
        axis.title.y = element_text(
          size = 11,
          margin = margin(
            t = 1,
            r = 1,
            b = 0,
            l = 0,
            unit = "mm"
          )
        ),
        axis.text.x = element_text(size = 11),
        axis.text.y = element_text(size = 11),
        axis.line.y.right = element_blank(),
        axis.title.y.right = element_blank(),
        axis.text.y.right = element_blank(),
        axis.ticks.y.right = element_blank()
      ) + 
      labs(x = NULL, y = "stdVector")
    
    
    # generated annotation vector
    p2mp_av <- plot_sequence(
      type = "raw",
      dataset = df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "av",
      y_lab = "AV"
    )
    
    ## DISCORD DISCOVERY on annotated MP
    discord <- find_discord(mp_annotated,
                            n_discords = 1,
                            n_neighbors = 1
    )
    sequence_string <- "Discord"
    # discord index
    sequence_index <- as.numeric(discord$discord$discord_idx)
    
    
    p3data <-  plot_sequence(
      type = "data",
      dataset = df_mp_univariate,
      x = "data_index",
      x_lab = NULL,
      y = "data",
      y_lab = "Total Power [kW]",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_annotated_index[sequence_index]
    )
    
    
    p3mp_new <-  plot_sequence(
      type = "mp",
      dataset = df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "mp_annotated",
      y_lab = "MP original",
      ymax_mp = ymax_mp,
      mp_index = "mp_annotated_index",
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_annotated_index[sequence_index]
    )
    
    dev.new()
    
    fig <- ggarrange(
      p0data,
      p1mp_old,
      p2mp_av_debug,
      p2mp_av,
      p3data,
      p3mp_new, 
      ncol = 1,
      nrow = 6,
      widths = c(3),
      align = "v"
    )
    
    annotate_figure(fig, top = text_grob(paste("Custom AV using ", ts_for_AV_name), color = "black", face = "bold", size = 13))
    
    ggsave( gsub(" ", "", paste("./figures/03-focus-custom-annotation-vector/",ts_for_AV_name,"/01-custom-AV-", ts_for_AV_name ,".png")),
            width = 13,
            height = 10)
    dev.off()
  }
  

  # plot discord profiles normal and normalized
  {
    
    ## DISCORD DISCOVERY on original MP
    discord <- find_discord(mp_univariate,
                            n_discords = 1,
                            n_neighbors = 1
    )
    sequence_string <- "Discord"
    # discord index
    sequence_index <- as.numeric(discord$discord$discord_idx)

    pmp_original_discord_z <-  plot_window(
      type = "znorm",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_original_index[sequence_index]
    )
    
    pmp_original_discord_pure <-  plot_window(
      type = "pure",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_original_index[sequence_index]
    )
    
   
    ## DISCORD DISCOVERY on original MP
    discord <- find_discord(mp_annotated,
                            n_discords = 1,
                            n_neighbors = 1
    )
    sequence_string <- "Discord"
    # discord index
    sequence_index <- as.numeric(discord$discord$discord_idx)
    
    pmp_annotated_discord_z <-  plot_window(
      type = "znorm",
      dataset = df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_annotated_index[sequence_index]
    )
    
    pmp_annotated_discord_pure <-  plot_window(
      type = "pure",
      dataset = df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "data",
      y_lab = NULL,
      w = w,
      seq_index = sequence_index,
      seq_nn = df_mp_univariate$mp_annotated_index[sequence_index]
    )
    
    dev.new()
    
    fig <-  ggarrange(
      pmp_original_discord_pure, pmp_original_discord_z,
      pmp_annotated_discord_pure, pmp_annotated_discord_z, 
      ncol = 2,
      nrow = 2,
      widths = c(3,3),
      align = "v"
    )
    
    annotate_figure(fig,
                    top = text_grob(paste(sequence_string, "discovery window profile"), color = "black", face = "bold", size = 13),
                    left = text_grob("Power [kW]", color = "black", size = 11, rot = 90),
                    right = text_grob("Power [z-norm]", color = "black",  size = 11, rot = 90),
                    bottom = text_grob("Obs. Index", color = "black",  size = 11)
                    
    )
    
    ggsave( gsub(" ", "", paste("./figures/03-focus-custom-annotation-vector/02-custom-AV-", ts_for_AV_name ,"-profile.png")),
            width = 7,
            height = 9
    )
     dev.off()
  }
  
  
}





