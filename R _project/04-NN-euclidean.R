#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source(file = "00-setup.R") # load user functions


#  MATRIX PROFILE ------------------------------------------------------------------


data <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/df_univariate_small.csv") %>%
  select(Power_total)

data <- data[1:3906,]

mp_not_norm1 <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/mp_not_normalized1NN.csv",
                         col.names = c("row","pi", "mp")) %>%
  dplyr::mutate(
    index = row+1,
    mp1 = mp,
    pi1 = pi
  ) %>%
  select(index, mp1, pi1)

mp_not_norm2 <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/mp_not_normalized2NN.csv",
                         col.names = c("row","pi", "mp")) %>%
  dplyr::mutate(
    row = row+1,
    mp2 = mp,
    pi2 = pi
  ) %>%
  select(mp2, pi2)

mp_not_norm3 <- read.csv(file = "/Users/robi/Desktop/matrix_profile/Roberto Chiosa/Python_project/data/mp_not_normalized3NN.csv",
                         col.names = c("row","pi", "mp")) %>%
  dplyr::mutate(
    row = row+1,
    mp3 = mp,
    pi3 = pi
  ) %>%
  select(mp3, pi3)

full_df <- cbind(mp_not_norm1,mp_not_norm2,mp_not_norm3, data) 



full_df1 <- full_df %>%
  select(index, mp1, mp2,mp3) %>%
  tidyr::pivot_longer(cols = c(mp1, mp2,mp3), names_to = "type", values_to = "values")

p1 <- ggplot(full_df1) + 
  geom_line(aes(x = index, y = values, color = type))+
  theme_bw() +
  labs(x = NULL, y = "Distance") + 
  theme(legend.position = "top")


p2 <- ggplot(full_df) + 
  geom_line(aes(x = index, y = data), color = "black") +
  labs(x = "Index", y = "Power[kW]") + 
  theme_bw() 


fig <-  ggarrange(
  p1, p2,
  ncol = 1,
  nrow = 2,
  widths = c(3,3),
  align = "v"
)

fig




sequence_index <- 100
w <- 96

pattern_1nn <-  plot_window(
  type = "pure",
  full_df,
  x = "index",
  x_lab = NULL,
  y = "data",
  y_lab = NULL,
  w = w,
  seq_index = sequence_index ,
  seq_nn =  full_df$pi1[sequence_index]
)






#######
#######try to find sense among sequences

annotated <- NULL
for (i in 1:length(data) ) {
  id <- i
  w <-  96
  
  Tij <- data[id:(id+w)]
  
  # get 1nn profile
  id_1nn <- mp_not_norm1$pi1[id]
  Tij_1nn <- data[id_1nn:(id_1nn+w)]
  
  # get 2nn profile
  id_2nn <- mp_not_norm2$pi2[id]
  Tij_2nn <- data[id_2nn:(id_2nn+w)]
  
  # get 3nn profile
  id_3nn <- mp_not_norm3$pi3[id]
  Tij_3nn <- data[id_3nn:(id_3nn+w)]
  
  
  df <- as.data.frame( cbind(Tij,Tij_1nn,Tij_2nn,Tij_3nn) ) %>%
    mutate(
      Tij_en = cumsum(Tij)-Tij[1],
      Tij_1nn_en = cumsum(Tij_1nn)-Tij_1nn[1],
      Tij_2nn_en = cumsum(Tij_2nn)-Tij_2nn[1],
      Tij_3nn_en = cumsum(Tij_3nn)-Tij_3nn[1]
    )
  
  
  # df_power <- df %>%
  #   mutate(index = as.integer(rownames(df))) %>%
  #   tidyr::pivot_longer(cols = c(Tij,Tij_1nn,Tij_2nn,Tij_3nn), names_to = "Nearest", values_to = "values")
  # 
  # ggplot(df_power)+
  #   geom_line(aes(x=index,y=values,color = Nearest))
  # 
  # df_energy <- df %>%
  #   mutate(index = as.integer(rownames(df))) %>%
  #   tidyr::pivot_longer(cols = c(Tij_en,Tij_1nn_en,Tij_2nn_en,Tij_3nn_en), names_to = "Nearest", values_to = "values")
  # 
  # ggplot(df_energy)+
  #   geom_line(aes(x=index,y=values,color = Nearest))
  
  
  valoreee <- last(df$Tij_en)-last(df$Tij_1nn_en) 
  if (valoreee<0) {
    valoreee=NA
  }
  # +
  #   last(df$Tij_en)-last(df$Tij_2nn_en) +
  #   last(df$Tij_en)-last(df$Tij_3nn_en)
 
  annotated[i] <-  valoreee
}

annotated <- as.data.frame(annotated)

annotated$index <- as.integer(rownames(annotated))

ggplot()+
  geom_line(data = annotated, aes(x=index,y=annotated)) +

geom_line(data = full_df1, aes(x = index, y = values, color = type))+
  theme_bw() +
  labs(x = NULL, y = "Distance") + 
  theme(legend.position = "top")




