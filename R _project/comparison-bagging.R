#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions



data <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/prova_T.csv", col.names = c("index","data")) %>% select(data)
data <- data[1:951,]
znorm <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/prova_matrix_profile_znorm.csv", col.names = c("index","znorm", "0", "3", "4")) %>% select(znorm)

notnorm <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/prova_matrix_profile_notnorm.csv", col.names = c("index","notnorm","0", "3", "4")) %>% select(notnorm)

notnorm1 <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/prova_kMP_0.csv", col.names = c("index","mpindex","notnorm1")) %>% select(notnorm1)

notnorm2 <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/prova_kMP_1.csv", col.names = c("index","mpindex","notnorm2")) %>% select(notnorm2)

notnorm3 <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/prova_kMP_2.csv", col.names = c("index","mpindex", "notnorm3")) %>% select(notnorm3)

notnorm4 <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/prova_kMP_3.csv", col.names = c("index","mpindex","notnorm4")) %>% select(notnorm4)


full_df <- cbind(data,znorm,notnorm, notnorm1, notnorm2, notnorm3, notnorm4)

full_df <- full_df %>%
  mutate(index = as.integer(rownames(full_df)))

full_df1 <- tidyr::pivot_longer(full_df, cols = c(data,znorm,notnorm, notnorm1, notnorm2, notnorm3, notnorm4), names_to = "type", values_to = "values")

ggplot(full_df1, aes(x = index, y = values)) + geom_line() + facet_wrap(~type, ncol = 1)
