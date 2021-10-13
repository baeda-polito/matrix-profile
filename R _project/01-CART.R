#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions


df <- read.csv('/Users/robi/Desktop/matrix_profile/Simone Deho/df_cabinaC_2019_labeled.csv', sep = ',') 

df_cart <- df %>%
  dplyr::mutate(
    Date = as.Date(Date_Time),
    Holiday = as.factor(Holiday),
    Day_Description = as.factor(Day_Description),
    Day_Type = as.factor(Day_Type)
  )  %>%
  dplyr::select(-Date_Time, -Time, - min_dec, - Year, -Month,- Hour, -Minute, -Second, -Day) %>%
  group_by(Date, Holiday, Day_Description, Day_Type) %>%
  summarise(across(is.numeric, mean))





ct <- rpart::rpart(
  # stats::reformulate(response = 'Total_Power' , termlabels = colnames(df_cart)[6:32] ),
  # stats::reformulate(response = 'Total_Power' , termlabels = colnames(df_cart)[15:32] ),
  Total_Power ~   Day_Description +Holiday + Day_Type + AirTemp,
  data = df_cart,                                                               # data to be used
  control = rpart::rpart.control(minbucket = 20)
)

# minsplit:     Set the minimum number of observations in the node before the algorithm perform a split
# minbucket:    Set the minimum number of observations in the final note i.e. the leaf
# maxdepth:     Set the maximum depth of any node of the final tree. The root node is treated a depth 0

# Training error (error in predicting training data): relerror
# Crossvalidation error (predictive error in x-validation): xerror
# Complexity parameter: cp
summary(ct)
print(ct)
printcp(ct)


# stampa complexity parameter
# dev.new()
#png(file = "TIME_WINDOW/CVcp.png", bg = "white", width = 500, height = 300)    
rpart::plotcp(ct, lty = 2, col = "red", upper = "size")
#dev.off()

# stampa albero
#dev.new() 
# png(file = "TIME_WINDOW/regressive_tree.png", bg = "white", width = 700, height = 400)  
ct1 <- partykit::as.party(ct)
#names(ct1$data) <- c("Total Power", "Hour") # change labels to plot
plot(ct1, tnex = 2.5,  gp = grid::gpar(fontsize = 12))
#dev.off()
