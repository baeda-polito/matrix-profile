#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
library(magrittr)
library(dplyr)
library(lubridate)
library(rpart)
library(partykit)

# try to define daily context in unsupervided way through CART





df <-  read.csv(file.path(dirname(dirname(getwd())), "Simone Deho", "df_cabinaC_2019_labeled.csv"), sep = ',') %>%
  dplyr::select(Date, Day_Type, Total_Power, AirTemp, Holiday) %>%
  dplyr::mutate( 
    Date = as.Date(Date),
    Holiday = as.factor(Holiday)
    ) %>%
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
  dplyr::select(Date, Holiday) %>%
  dplyr::mutate( 
    Date = as.Date(Date),
    Holiday = as.factor(Holiday)
  ) %>%
  unique()
  
df1 <- merge.data.frame(df, df_tmp)

ct <- rpart::rpart(Energy ~ Day_Type + AirTemp + Holiday,                                                    # target attribute based on training attributes
                   data = df1,                                                               # data to be used
                   control = rpart::rpart.control(
                     minbucket = 35,  # 120 min 15 minutes sampling*number of days
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

png(file = file.path("Polito_Usecase", "figures", "cart_groups_cp.png"), bg = "white", width = 500, height = 300)    
plotcp(ct, lty = 2, col = "red", upper = "size")
dev.off()

# stampa albero
dev.new() 
png(file = file.path("Polito_Usecase", "figures", "cart_groups.png"), bg = "white", width = 700, height = 400)  
ct1 <- partykit::as.party(ct)
#names(ct1$data) <- c("Total Power", "Temp") # change labels to plot
plot(ct1, tnex = 2.5,  gp = gpar(fontsize = 8))
dev.off()


library(mltools)
library(data.table)

dt <- data.table(
  timestamp = df1$Date,
  Node = as.factor(ct$where)
) %>%
one_hot()

df_py_holiday <- as.data.frame(dt) %>%
  mutate(across(is.numeric, as.logical))

write.csv(df_py_holiday, file = file.path("Polito_Usecase", "data", "polito_holiday.csv"), row.names = FALSE)



