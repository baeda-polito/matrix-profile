#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions

df <- read.csv('./data/df_cabinaC_power_meteo_2015_2019.csv', sep = ',') %>%
  mutate(
    Date_Time = as.POSIXct(Date_Time , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
    Date = as.Date(Date_Time),
    Time = as.factor(Time),
    ToU = as.factor(FasciaAEEG),
    Holiday = if_else(festivo == "S", TRUE, FALSE),
    T_air = TempARIA,
    H_global = RadGLOBale
  ) %>%
  dplyr::select(-c("TempARIA", "RadGLOBale", "festivo", "FasciaAEEG"))

# extract colnames in order of magnitude to sort df
tmp <- df %>%
  select(is.numeric) %>% # select only numeric
  select(-H_global, -T_air, -min_dec, -Day_Type) %>%
  summarise(across(everything(), list(mean = mean))) %>% # summarise mean
  t() %>%
  as.data.frame() %>%
  arrange(desc(V1))



df <- df %>%
  select(colnames(df)[1:5], "T_air", "H_global", gsub("_mean", "", rownames(tmp)))
  
write.csv(df, "./data/df_cabinaC_full.csv")

            