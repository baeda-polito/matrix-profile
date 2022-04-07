#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("global_vars.R")     # Loads global variables
source("utils_functions.R") # Loads utils functions

library(dplyr)
# load the context decoder dataframe
df <-
  read.csv(file.path("Polito_Usecase", "diagnosis", "diagnosis_final.csv")) 

# SECTION ------------------------------------
severity_vector <- c(4:10)

df_list <- df %>% 
  select(all_of(severity_vector)) %>% 
  apply(1,function(x) which(x==max(x))) %>% 
  lapply(function(x) toString(names(x))) %>% 
  unlist()

df_list_sev <- df %>% 
  select(all_of(severity_vector)) %>% 
  apply(1,function(x) which(x==max(x))) %>% 
  lapply(function(x) toString(x)) %>% 
  unlist()



df$responsible <- df_list

df %>% 
  select(responsible, Total_Power) %>% 
  group_by(responsible) %>% 
  count() %>% 
  arrange(desc(n))

# SECTION ------------------------------------
energy_vector <- c(12:18)

df_list <- df %>% 
  select(all_of(energy_vector)) %>% 
  apply(1,function(x) which(x==max(x))) 

df$responsible <- colnames(select(df, all_of(energy_vector)))[df_list]


df %>% 
  select(responsible, Total_Power) %>% 
  group_by(responsible) %>% 
  count() %>% 
  arrange(desc(n))



