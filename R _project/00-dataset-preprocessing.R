#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions


df <- read.csv('/Users/robi/Desktop/matrix_profile/Simone Deho/df_cabinaC_2019_labeled.csv', sep = ',') 

tt <- df %>%
  select(Date, Holiday, Day_Description) %>%
  unique()
  


df_py <- df %>%
  mutate(
    timestamp = Date_Time,
    value = Total_Power
  ) %>%
  dplyr::select(timestamp, value)

summary(df_py)

write.csv(df_py, file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/CMP/Polito_Usecase/data/polito.csv", row.names = FALSE)


as.integer(as.factor(df$Holiday))
# holiday annotation
df_py_holiday <- df %>%
  mutate(
    timestamp = as.Date(Date_Time),
    week_day = lubridate::wday(timestamp, week_start = getOption("lubridate.week.start", 1)),
    holiday_bool = as.logical( as.integer(as.factor(df$Holiday))-1 ),
    #holiday_bool = ifelse( timestamp %in% as.Date(hol), TRUE, holiday_bool), # add not counted holidays
    saturday_bool = if_else( !holiday_bool & week_day == 6, TRUE, FALSE),
    workingday_bool = if_else( !holiday_bool & week_day != 6 & week_day != 7, TRUE, FALSE),
  ) %>%
  dplyr::select(timestamp, holiday_bool, saturday_bool, workingday_bool) %>%
  unique()


colnames(df_py_holiday)[2] <- "Holiday"
colnames(df_py_holiday)[3] <- "Saturday"
colnames(df_py_holiday)[4] <- "Working Day"
# 
# # create a fill dataframe
# start <- df_py_holiday$timestamp[1]
# interval <- 60*24
# 
# end <- start + as.difftime(151, units="days")
# 
# ttt <- data.frame(timestamp = seq(from=start, by=1, to=end))
# 
# df_py_holiday <- merge.data.frame(ttt, df_py_holiday, all.x =  T)
# df_py_holiday <- df_py_holiday[1:151,]


write.csv(df_py_holiday, file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/CMP/Polito_Usecase/data/polito_holiday.csv", row.names = FALSE)




            