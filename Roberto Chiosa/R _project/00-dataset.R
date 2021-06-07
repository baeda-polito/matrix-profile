#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

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
  dplyr::select(-c(2:9))

save(df_univariate, file = gsub(" ", "", paste("./data/df_univariate_full.RData")))

# subset original dataframe
df_univariate <- df_univariate[c(6000:10000),]

# reset rownames from 1 to end
rownames(df_univariate) <- c(6000:10000)-6000+1

save(df_univariate, file = gsub(" ", "", paste("./data/df_univariate_small.RData")))

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
  
  ggsave("./figures/00-dataset/01-dataset.png",
         width = 10,
         height = 13)
  dev.off()
}