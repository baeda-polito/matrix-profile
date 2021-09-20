#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
source("utils_functions.R")

library(magrittr)
library(dplyr)
library(lubridate)
library(rpart)
library(partykit)
library(mltools)
library(data.table)

# load dataset of sub daily time windows
context_df <- read.csv(file.path("Polito_Usecase", "data", "time_window.csv"))
m_context <- read.csv(file.path("Polito_Usecase", "data", "m_context.csv"))[1,1]


# for each time window try to define homogeneous groups through CART
# calculate values referring to the time window and predict
# no more than 3-4 groups per time window

for (i in 1:dim(context_df)[1]) {
  
  if (i==1) {
    context_start <-  0  # [hours]
    context_end <-  context_start + m_context  # [hours]
    m = as.integer( (hour_to_dec(context_df$to[i])-m_context)* 4)
  } else{
    m = context_df$observations[i]  # # [observations] data driven
    context_end <- hour_to_dec(context_df$from[i])  # [hours]
    context_start <-  context_end - m_context  # [hours]
  }
     
    

  # contracted context string for names
  context_string_small <-  paste('ctx_from',  
                                 dec_to_hour(context_start),
                                 '_to',
                                 dec_to_hour(context_end),
                                 "_m",
                                 dec_to_hour(m/ 4), 
                                 sep = "") 
  
  context_string_small <- gsub(":", "_", context_string_small)
  
  # create directories if not existing
  figures_path_folder <- file.path("Polito_Usecase", "figures", context_string_small)
  data_path_folder <- file.path("Polito_Usecase", "data", context_string_small)
  
  if ( file.exists(figures_path_folder ) == FALSE ){ # directory does not exists
    dir.create( figures_path_folder )
  }
  
  if ( file.exists(data_path_folder ) == FALSE ){ # directory does not exists
    dir.create( data_path_folder )
  }
  
  
  
  # try to define groups in each time window in unsupervided way through CART
  df <-  read.csv(file.path(dirname(dirname(getwd())), "Simone Deho", "df_cabinaC_2019_labeled.csv"), sep = ',') %>%
    dplyr::mutate( 
      Date = as.Date(Date),
      Holiday = as.factor(Holiday),
      Time_Window = ifelse(min_dec >= hour_to_dec(context_df$from[i]) & min_dec <= hour_to_dec(context_df$to[i]), 1, 0 )
    ) %>%
    dplyr::select(Date, Day_Type, Total_Power, AirTemp, Holiday, Time_Window) %>%
    dplyr::filter(Time_Window == 1) %>%
    dplyr::group_by(Date) %>%
    dplyr::summarise(
      Energy = sum(Total_Power),
      AirTemp = mean(AirTemp)
    ) %>%
    dplyr::mutate(
      Day_Type = lubridate::wday(Date, week_start = getOption("lubridate.week.start", 1), label = T ),
      Day_Type = factor(Day_Type, ordered = F)
    )
  
  df_tmp <-  read.csv(file.path(dirname(dirname(getwd())), "Simone Deho", "df_cabinaC_2019_labeled.csv"), sep = ',') %>%
    dplyr::select(Date, Day_Type, Holiday, Day_Description) %>%
    dplyr::mutate( 
      Date = as.Date(Date),
      Holiday = as.factor(Holiday)
    ) %>%
    unique()
  
  df_tmp$Holiday[df_tmp$Date == "2019-04-27"] <- "Yes"
  df_tmp$Holiday[df_tmp$Date == "2019-08-17"] <- "Yes"
  df_tmp$Holiday[df_tmp$Date == "2019-12-23"] <- "Yes"
  df_tmp$Holiday[df_tmp$Date == "2019-12-24"] <- "Yes"
  
  df_tmp <- df_tmp %>%
    mutate(
    Holiday1 = as.factor(ifelse(Holiday == "Yes", "full", ifelse(Day_Type == 6, "half", "none")))
  ) %>%
    dplyr::select(Date, Holiday)
  
  
  
  df1 <- merge.data.frame(df, df_tmp)
  
  ct <- rpart::rpart(Energy ~ Day_Type + AirTemp + Holiday,                                                    # target attribute based on training attributes
                     data = df1,                                                               # data to be used
                     control = rpart::rpart.control(
                       minbucket = 30,  # 120 min 15 minutes sampling*number of days
                       cp = 0 ,                                          # nessun vincolo sul cp permette lo svoluppo completo dell'albero
                       # xval = (length(df) - 1 ),                        # !!!!!!! ATTENZIONE non dovrebbe essere dim()[1] ?? k-fold leave one out LOOCV dim
                       xval = 30,                        # !!!!!!! ATTENZIONE non dovrebbe essere dim()[1] ?? k-fold leave one out LOOCV dim
                       maxdepth = 3)
  ) 
  
  # minsplit:     Set the minimum number of observations in the node before the algorithm perform a split
  # minbucket:    Set the minimum number of observations in the final note i.e. the leaf
  # maxdepth:     Set the maximum depth of any node of the final tree. The root node is treated a depth 0
  
  
  # stampa complexity parameter
  dev.new()
  png(file = file.path(figures_path_folder, "groups_cp.png" ), 
      bg = "white", width = 2000, height = 1300, res = dpi) 
  plotcp(ct, lty = 2, col = "red", upper = "size")
  dev.off()
  
  # stampa albero
  dev.new() 
  png(file = file.path(figures_path_folder, "groups_cart.png"),
      bg = "white", width = 2000, height = 1400, res = dpi)  
  ct1 <- partykit::as.party(ct)
  #names(ct1$data) <- c("Total Power", "Temp") # change labels to plot
  plot(ct1, tnex = 2.5,  gp = gpar(fontsize = 8))
  dev.off()
  
  
  dt <- data.table(
    timestamp = df1$Date,
    Node = as.factor(ct$where)
  ) %>%
    one_hot()
  
  df_py_holiday <- as.data.frame(dt) %>%
    mutate(across(is.numeric, as.logical))
  
  write.csv(df_py_holiday, file = file.path(data_path_folder,"groups.csv"), row.names = FALSE)
  
}




