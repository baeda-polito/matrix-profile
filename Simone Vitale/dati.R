df <- read.csv("./euclidean_MP/data/df_univariate_full.csv",header = T,sep = ';')
df_1 <- read.csv("./euclidean_MP/data/df_univariate_small.csv")

df_twomonths <- df[1:5855,]
df_twomonths$X<-c(1:nrow(df_twomonths))
df_twomonths[c(11:18)] <- lapply(df_twomonths[c(11:18)], function(i) as.numeric(sub(',', '.', i, fixed = TRUE)))

write.csv(df_twomonths,'./euclidean_MP/data/df_two_months.csv')
