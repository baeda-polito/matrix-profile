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

df_py <- df_univariate %>%
  mutate(
    timestamp = CET,
    value = Power_total
  ) %>%
  dplyr::select(timestamp, value)


# create a fill dataframe
start <- df_py$timestamp[1]
interval <- 15

end <- start + as.difftime(151, units="days")

ttt <- data.frame(timestamp = seq(from=start, by=interval*60, to=end))

df_py <- merge.data.frame(ttt, df_py, all.x =  T)

last(df_py$timestamp)

summary(df_py)

df_py$value <- imputeTS::na_interpolation(df_py$value)


df_py <- df_py[1:14496,]

write.csv(df_py, file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/CMP/Polito_Usecase/polito.csv", row.names = FALSE)

# holiday annotation
df_py_holiday <- df_univariate %>%
  mutate(
    timestamp = as.Date(CET),
    Holiday = as.logical( as.integer(Holiday)-1 )
  ) %>%
  dplyr::select(timestamp, Holiday) %>%
  unique()


# create a fill dataframe
start <- df_py_holiday$timestamp[1]
interval <- 60*24

end <- start + as.difftime(151, units="days")

ttt <- data.frame(timestamp = seq(from=start, by=1, to=end))

df_py_holiday <- merge.data.frame(ttt, df_py_holiday, all.x =  T)
df_py_holiday <- df_py_holiday[1:151,]

write.csv(df_py_holiday, file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/CMP/Polito_Usecase/polito_holiday.csv", row.names = FALSE)

# subset original dataframe 
# - from 2018-01-15 00:00:00 (row 106129)
# - to 2018-05-15 00:00:00 (row 117645)
from_index <- 106129
to_index <- 117645

df_univariate <- df_univariate[c(from_index:to_index),]
# reset rownames from 1 to end
rownames(df_univariate) <- c(from_index:to_index)-from_index+1


save(df_univariate, file = gsub(" ", "", paste("./data/df_univariate_small.RData")))
write.csv(df_univariate, file = gsub(" ", "", paste("./data/df_univariate_small.csv")))

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
