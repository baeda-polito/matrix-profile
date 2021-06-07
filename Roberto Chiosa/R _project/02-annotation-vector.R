#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

load( "./data/df_univariate_small.RData" ) # load to save time

variable <- "Power_total"                                         # this is the timeseries used to perform the MP
w <- 96                                                           # window size # this is the window size used to compute the MP
figure_path <- "./figures/02-annotation-vector/"                  # path to figure  directory

av_type <- c("complexity", "hardlimit_artifact", "motion_artifact", "zerocrossing", "make_AV_complexity", "make_AV_motion_real", "make_AV_motion_binary")

for (i in 1:length(av_type)) {
  
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
    mp_original = mp_univariate$mp
  )
  
  
  # depending on the type
  switch (av_type[i],
          complexity                = mp_annotated <- av_complexity(mp_univariate, apply = TRUE),
          hardlimit_artifact        = mp_annotated <- av_hardlimit_artifact(mp_univariate, apply = TRUE),
          motion_artifact           = mp_annotated <- av_motion_artifact(mp_univariate, apply = TRUE),
          zerocrossing              = mp_annotated <- av_zerocrossing(mp_univariate, apply = TRUE),
          # custom av need to be created and thenn applied to MP
          make_AV_complexity        ={
            mp_univariate$av     <- make_AV( data = mp_univariate$data[[1]], subsequenceLength = w, type = 'complexity')
            class(mp_univariate) <- tsmp:::update_class(class(mp_univariate), "AnnotationVector")
            mp_annotated         <- tsmp::av_apply(mp_univariate)
          },
          make_AV_motion_real       ={
            mp_univariate$av     <-  make_AV( data = mp_univariate$data[[1]], subsequenceLength = w, type = 'motion_artifact', binary = FALSE)
            class(mp_univariate) <- tsmp:::update_class(class(mp_univariate), "AnnotationVector")
            mp_annotated         <- tsmp::av_apply(mp_univariate)
          },
          make_AV_motion_binary     ={
            mp_univariate$av     <- make_AV( data = mp_univariate$data[[1]], subsequenceLength = w, type = 'motion_artifact', binary = TRUE)
            class(mp_univariate) <- tsmp:::update_class(class(mp_univariate), "AnnotationVector")
            mp_annotated         <- tsmp::av_apply(mp_univariate)
          }
  )
  
  # adds annotated results of mp
  df_mp_univariate$mp_annotated <- mp_annotated$mp
  df_mp_univariate$av           <- mp_annotated$av
  
  # plot
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
    
    p1mp_old <- plot_sequence(
      type = "raw",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "mp_original",
      y_lab = paste("MP - w",w),
      ymax_mp = 20,
      mp_index = "mp_index"
    )
    
    p2mp_av <- plot_sequence(
      type = "raw",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "av",
      y_lab = "AV [-]"
    )
    
    p3mp_new <- plot_sequence(
      type = "raw",
      df_mp_univariate,
      x = "index",
      x_lab = NULL,
      y = "mp_annotated",
      y_lab = paste("CMP - w",w),
      ymax_mp = 20,
      mp_index = "mp_index"
    )
    
    dev.new()
    
    fig <- ggarrange(
      p0data,
      p1mp_old,
      p2mp_av,
      p3mp_new, 
      ncol = 1,
      nrow = 4,
      widths = c(3),
      align = "v"
    )
    
    annotate_figure(fig, top = text_grob(paste("Annotation Vector :", av_type[i]), color = "black", face = "bold", size = 13))
    
    ggsave( gsub(" ", "", paste(figure_path <- "./figures/02-annotation-vector/", av_type[i], ".png")),
            width = 10,
            height = 7)
    dev.off()
  }
  
}




