#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

load( "./data/df_univariate_small.RData" ) # load to save time
w = 96 # window size

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

# !!!!!!!!!!!!!!
# to make the AV we can use a custom timeseries, not only the original timeseries
ts_for_AV_name <- c("Power_data_centre")
ts_for_AV <-  as.numeric(df_univariate$Power_data_centre)


## go on
mp_univariate$av <-  make_AV( data = ts_for_AV, subsequenceLength = w, type = 'motion_artifact', binary = TRUE, debug_mode = TRUE)$AV
mp_univariate$stdVector <-  make_AV( data = ts_for_AV, subsequenceLength = w, type = 'motion_artifact', binary = TRUE, debug_mode = TRUE)$stdVector
class(mp_univariate) <-tsmp:::update_class(class(mp_univariate), "AnnotationVector")
mp_annotated <- tsmp::av_apply(mp_univariate)


# adds annotated results of mp
df_mp_univariate$mp_annotated <- mp_annotated$mp
df_mp_univariate$av <- mp_annotated$av
df_mp_univariate$stdVector <- mp_annotated$stdVector
df_mp_univariate$mean_stdVector <-rep( mean(mp_annotated$stdVector), length(mp_annotated$stdVector))

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
    y_lab = "MP original",
    ymax_mp = 20,
    mp_index = "mp_index"
  )
  
  coeff =  max(ts_for_AV[c(1: (length(ts_for_AV)-w+1)) ])/ max(df_mp_univariate$stdVector)
    
  p2mp_av_debug <- ggplot(df_mp_univariate) +
    geom_line( aes_string(x = "index", y = "stdVector"),  color = "red") +
    geom_line( aes_string(x = "index", y = "mean_stdVector"),  color = "green") +
    geom_line( aes(x = index, y = ts_for_AV[c(1: (length(ts_for_AV)-w+1)) ] /coeff),  color = "gray") +
    scale_y_continuous(
      # Add a second axis and specify its features
      sec.axis = sec_axis(~.*coeff)
    )+
    theme_bw() +
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
      axis.ticks.y.right = element_blank(),
      axis.title.y.right = element_blank(),
      axis.text.y.right = element_blank()
    ) + 
    labs(x = NULL, y = "stdVector [kW]")
  
  
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
    y_lab = "MP annotated",
    ymax_mp = 20,
    mp_index = "mp_index"
  )
  
  
  
  dev.new()
  
  fig <- ggarrange(
    p0data,
    p1mp_old,
    p2mp_av_debug,
    p2mp_av,
    p3mp_new, 
    ncol = 1,
    nrow = 5,
    widths = c(3),
    align = "v"
  )
  
  annotate_figure(fig, top = text_grob(paste("Custom AV using ", ts_for_AV_name), color = "black", face = "bold", size = 13))
  
  ggsave( gsub(" ", "", paste("./figures/03-focus-custom-annotation-vector/01-custom-AV-", ts_for_AV_name ,".png")),
          width = 10,
          height = 7)
  dev.off()
}






