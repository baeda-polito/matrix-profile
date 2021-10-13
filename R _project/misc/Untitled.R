library("tsmp")

df <- read.csv("./data_comparison.csv", sep = ",")[c(0: 3360),]


# To install the latest version from Github:
# install.packages("devtools")
devtools::install_github("tylermorganwall/rayshader")



df1 <- dplyr::mutate(df, Timestamp = as.POSIXct(DATA_ORA_MINUTI_RILEVAMENTO_BASE , format = "%Y-%m-%d %H:%M:%S" , tz = "Etc/GMT+12"),
                     Power = X1226,
                     index = as.integer(rownames(df)),
                     festivo = as.factor(festivo),
                     min_dec = paste(lubridate::hour(Timestamp), lubridate::minute(Timestamp)*100/60, sep = "."),
                     DayType = lubridate::wday(Timestamp, label = TRUE, locale = Sys.setlocale("LC_TIME","en_US.UTF-8"))
)

df2 <- dplyr::select(df1, Timestamp, Power, festivo, DayType, min_dec, index  )

df_feriali <- dplyr::filter(df2, festivo == "N" & DayType!= 6 & DayType!= 7)
df_nigth <- dplyr::filter(df2, min_dec <= 5, min_dec >=21)
df_festivi <- dplyr::filter(df2, festivo == "S" | DayType== 6 | DayType== 7)

mp00 <- analyze(df_feriali$Power, windows = 96/4)$mp
mp0 <- analyze(df_feriali$Power, windows = 96/2)$mp
mp1 <- analyze(df_feriali$Power, windows = 96)$mp
mp2 <- analyze(df_feriali$Power, windows = 96*2)$mp
mp3 <- analyze(df_feriali$Power, windows = 96*7)$mp

indexes <- df_feriali$index

p <- ggplot2::ggplot(df2, ggplot2::aes(x = index, y=Power)) + 
  ggplot2::geom_point() +  ggplot2::geom_line() + ggplot2::theme_classic()
ggExtra::ggMarginal(p, type = c("histogram"), margins = "y")
ggExtra::ggMarginal(p, type = c("boxplot"), margins = "y")


ggplot2::ggplot(df2, ggplot2::aes(y=Power)) + 
  ggplot2::geom_boxplot()

ggExtra::ggMarginal()

p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
ggExtra::ggMarginal(p)


par(mfrow=c(6,1), cex=0.2)
plot(df2$Power[df_feriali$index], type = "l",yaxt="n", axes=F, ylab="", xlab="")
plot(mp00[df_feriali$index], type = "l",yaxt="n", axes=F, ylab="", xlab="")
plot(mp0[df_feriali$index], type = "l",yaxt="n", axes=F, ylab="", xlab="")
plot(mp1[df_feriali$index], type = "l",yaxt="n", axes=F, ylab="", xlab="")
plot(mp2[df_feriali$index], type = "l",yaxt="n", axes=F, ylab="", xlab="")
plot(mp3[df_feriali$index], type = "l",yaxt="n", axes=F, ylab="", xlab="Index")

par(mfrow=c(6,1), cex=0.1)
plot(df2$Power[df_festivi$index], type = "l")
plot(mp00[df_festivi$index], type = "l")
plot(mp0[df_festivi$index], type = "l")
plot(mp1[df_festivi$index], type = "l")
plot(mp2[df_festivi$index], type = "l")
plot(mp3[df_festivi$index], type = "l")


par(mfrow=c(6,1), cex=0.1)
plot(df2$Power[df_nigth$index], type = "l")
plot(mp00[df_nigth$index], type = "l")
plot(mp0[df_nigth$index], type = "l")
plot(mp1[df_nigth$index], type = "l")
plot(mp2[df_nigth$index], type = "l")
plot(mp3[df_nigth$index], type = "l")

par(mfrow=c(6,1), cex=0.1)
plot(df_feriali$Power, type = "l")
plot(mp00, type = "l")
plot(mp0, type = "l")
plot(mp1, type = "l")
plot(mp2, type = "l")
plot(mp3, type = "l")


motifs <- tsmp(df2$Power, window_size = 96, exclusion_zone = 1/2) 
snippets <- find_snippet(mp_fluss_data$walkjogrun$data[1:300], 40, n_snippets = 2)


dfmp <- as.data.frame(motifs$mp)
ggplot2::ggplot(dfmp, ggplot2::aes(V1)) + 
  ggplot2::geom_line()

  find_motif(n_motifs = 3, radius = 10, exclusion_zone = 20) %T>%
  plot()


tseq <- seq(from = df2$Timestamp[1],  to =  df2$Timestamp[length(df2$Timestamp)], by = "15 min")

df2$Timestamp[96]


summary(df)



mp <- valmod(df$X294, window_min = 96/4, window_max = 96)
mp$w

mp <- tsmp(mp_toy_data$data[1:200, 1], window_size = 30, verbose = 0)

mp <- valmod(mp_toy_data$data[1:200, 1], window_min = 30, window_max = 40, verbose = 0)
# \donttest{
ref_data <- mp_toy_data$data[, 1]
query_data <- mp_toy_data$data[, 2]
# self similarity
mp <- valmod(ref_data, window_min = 30, window_max = 40)
# join similarity
mp <- valmod(ref_data, query_data, window_min = 30, window_max = 40)
# }
# 
# 
# 
# 
result$mp[c] <- 0
plot(mp)

w <- 50
data <- mp_gait_data
mp <- tsmp(data, window_size = w, exclusion_zone = 1 / 4, verbose = 0)
min_val <- min_mp_idx(mp)

plot(mp$data)

data <- mp_test_data$train$data[1:1000]
w <- 50
mp <- tsmp(data, window_size = w, verbose = 0)
mp <- av_complexity(mp)
av <- av_apply(mp)

ref_data <- mp_toy_data$data[, 1]
qe_data <- mp_toy_data$data[, 2]
qd_data <- mp_toy_data$data[150:200, 1]
w <- mp_toy_data$sub_len

# distance between data of same size
deq <- mpdist(ref_data, qe_data, w)

# distance between data of different sizes
ddiff <- mpdist(ref_data, qd_data, w)

# distance vector between data of different sizes
ddvect <- mpdist(ref_data, qd_data, w, type = "vector")


snippets <- find_snippet(mp_fluss_data$walkjogrun$data[1:300], 40, n_snippets = 2)
# \donttest{
snippets <- find_snippet(mp_fluss_data$walkjogrun$data, 120, n_snippets = 3)
plot(snippets)
# }
# 


df <- read.csv("/Users/robi/Desktop/aSAX/df_tot.csv")
df <- df[2017:15000,"Total_Power"]


data <- dplyr::mutate(df, WDAY = lubridate::wday(df$Date_Time, week_start = getOption("lubridate.week.start", 1)))
data <- dplyr::filter(data, WDAY != 6, WDAY != 7, festivo=='N')

data1 <- data[,"Total_Power"]

result <- analyze(data1,96)

motifs <- tsmp(df, window_size = 672, exclusion_zone = 1/2)  %>%
  find_motif(n_motifs = 3, radius = 10, exclusion_zone = 20) 


plot(motifs, type = c("matrix"), ncol = 3,main = "MOTIF Discover",
     xlab = "index",
     ylab = "")

plot(motifs, type = c("data"), ncol = 3,main = "MOTIF Discover",
     xlab = "index",
     ylab = "")


segments <- motifs %>% fluss(num_segments = 2)
segments

plot(segments, type = "data")

chains <- df %>% 
  tsmp(window_size = 96, exclusion_zone = 1/4, verbose = 0) %>%
  find_chains()

chains

plot(chains, ylab = "")

