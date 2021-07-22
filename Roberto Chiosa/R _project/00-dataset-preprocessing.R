#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

df_power <- read.csv('/Users/robi/Dropbox (Politecnico Di Torino Studenti)/aSAX/df_power.csv', sep = ',') %>%
  mutate(
    Date_Time = as.POSIXct(Date_Time , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
    Date = as.Date(Date_Time),
    Time = as.factor(Time),
    ToU = as.factor(FasciaAEEG),
    Holiday = if_else(festivo == "S", TRUE, FALSE)
  ) %>%
  dplyr::arrange(Date_Time) %>%
  dplyr::select(-c("festivo", "FasciaAEEG"))

df_meteo <- read.csv('/Users/robi/Dropbox (Politecnico Di Torino Studenti)/aSAX/df_clima.csv', sep = ',') %>%
  mutate(
    Date_Time = as.POSIXct(Date_Time , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
    T_air = TempARIA,
    H_global = RadGLOBale
  ) %>%
  dplyr::arrange(Date_Time) %>%
  dplyr::select("Date_Time", "T_air", "H_global")

# extract colnames in order of magnitude to sort df
tmp <- df_power %>%
  select(is.numeric) %>% # select only numeric
  select( -min_dec, -Day_Type) %>%
  summarise(across(everything(), list(mean = mean))) %>% # summarise mean
  t() %>%
  as.data.frame() %>%
  arrange(desc(V1))


# create a fill dataframe
start <- df_power$Date_Time[1]
interval <- 15

end <- start + as.difftime(length(unique(df_power$Date)), units="days")

ttt <- data.frame(Date_Time = seq(from=start, by=interval*60, to=end))


df_py <- merge.data.frame(ttt, df_power, all.x =  T)

df_py <- merge.data.frame(df_py, df_meteo, all.x =  T)


summary(df_py)


df_py <- df_py %>%
  select(colnames(df_py)[1:5], "T_air", "H_global", gsub("_mean", "", rownames(tmp)))
  

write.csv(df_py, "./data/df_cabinaC_full.csv")

            