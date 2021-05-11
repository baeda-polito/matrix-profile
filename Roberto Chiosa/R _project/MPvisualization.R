library(highcharter)
library(tsmp)

df <- read.csv("./df.csv", sep = ";")

df1 <- dplyr::mutate(df, 
                     Timestamp = as.POSIXct(DATA_ORA_MINUTI_RILEVAMENTO_BASE , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
                     Date = as.Date(Timestamp),
                     Power_total = df$X1226,
                     Power_data_centre = df$X1045,
                     Power_canteen = df$X1047,
                     Power_mechanical_room = df$X1022,
                     Power_dimat = df$X294,
                     Power_bar = df$X1046,
                     Power_rectory = df$X1085,
                     Power_print_shop = df$X1086,
                     index = as.integer(rownames(df)),
                     festivo = as.factor(festivo),
                     min_dec = as.numeric(paste(lubridate::hour(Timestamp), lubridate::minute(Timestamp)*100/60, sep = ".")),
                     DayType = lubridate::wday(Timestamp, label = TRUE, locale = Sys.setlocale("LC_TIME","en_US.UTF-8")),
                      AV = dplyr::if_else(min_dec >=6 & min_dec <= 12, 1, 0)
)

df <- energydataset::data_power_raw


plot(decompose(ts(df$`1086`, frequency = 96)))

data_inizio <- as.Date("2015-03-01")
df2<- df1 %>%
  dplyr::filter(Date > data_inizio & Date < data_inizio+365, AV == 1,
                DayType == "Sat" | festivo == "S" | DayType == "Sun") %>%
  # 
  dplyr::select(Timestamp,  festivo, DayType, min_dec, index, AV, Date,
                Power_total ,
                Power_mechanical_room ,
                Power_bar ,
                Power_data_centre ,
                Power_canteen ,
                Power_dimat ,
                Power_rectory ,
                Power_print_shop
  ) 

result_list = list()
subloads <- colnames(df2)[c(8:10)]

window_vector = c(96/2)

for (j in 1:length(window_vector)) {
  window = window_vector[j]
  
  day = trunc(window/96)
  hours = (window/96 - trunc(window/96) ) *24
  
  for (i in 1:length(subloads) ) {
    # result_list[[i]] <- compute(df2[[ subloads[i] ]], windows = window)
    
    result_list[[i]] <- tsmp(df2[[ subloads[i] ]], window_size = window)
  }
  
  # ttt <- compute(df2$Power_mechanical_room, windows = window, threshold = 1)
  # ttt <- tsmp(df2$Power_mechanical_room, window_size = window)
  # plot(ttt$data$ts, type = "l")
  # plot(ttt$mp, type = "l")
  
  names( result_list ) <- paste("MP", subloads)
  
  # highchart() %>%
  #   hc_add_series(result_list$`MP Power_total`$mp,  type = "line", name = "Power_total") %>%
  #   hc_add_series(result_list$`MP Power_data_centre`$mp,  type = "line", name = "Power_data_centre") %>%
  #   hc_add_series(result_list$`MP Power_canteen`$mp,  type = "line", name = "Power_canteen") %>%
  #   hc_add_series(result_list$`MP Power_mechanical_room`$mp,  type = "line", name = "Power_mechanical_room") %>%
  #   hc_add_series(result_list$`MP Power_dimat`$mp,  type = "line", name = "Power_dimat") %>%
  #   hc_add_series(result_list$`MP Power_bar`$mp,  type = "line", name = "Power_bar") %>%
  #   hc_add_series(result_list$`MP Power_rectory`$mp,  type = "line", name = "Power_rectory") %>%
  #   hc_add_series(result_list$`MP Power_print_shop`$mp,  type = "line", name = "Power_print_shop") 
  # 
  # highchart() %>%
  #   hc_add_series(result_list$`MP Power_total`$data$ts,  type = "line", name = "Power_total") %>%
  #   hc_add_series(result_list$`MP Power_data_centre`$data$ts,  type = "line", name = "Power_data_centre") %>%
  #   hc_add_series(result_list$`MP Power_canteen`$data$ts,  type = "line", name = "Power_canteen") %>%
  #   hc_add_series(result_list$`MP Power_mechanical_room`$data$ts,  type = "line", name = "Power_mechanical_room") %>%
  #   hc_add_series(result_list$`MP Power_dimat`$data$ts,  type = "line", name = "Power_dimat") %>%
  #   hc_add_series(result_list$`MP Power_bar`$data$ts,  type = "line", name = "Power_bar") %>%
  #   hc_add_series(result_list$`MP Power_rectory`$data$ts,  type = "line", name = "Power_rectory") %>%
  #   hc_add_series(result_list$`MP Power_print_shop`$data$ts,  type = "line", name = "Power_print_shop") 
  
  
  
  options(highcharter.theme = hc_theme_smpl(tooltip = list(valueDecimals = 2)))
  
  ts_data<- ts(
    data.frame( total = result_list$`MP Power_total`$data[[1]], 
                mechanical_room  = result_list$`MP Power_mechanical_room`$data[[1]],
                bar  = result_list$`MP Power_bar`$data[[1]])
  )
  
  ts_mp<- ts(
    data.frame( total = result_list$`MP Power_total`$mp, 
                mechanical_room = result_list$`MP Power_mechanical_room`$mp,
                bar = result_list$`MP Power_bar`$mp)
  )
  
  x <- cbind(
    ts_data,
    ts_mp
  )
  
  
  hc <- hchart( x )  %>%
    highcharter::hc_chart(zoomType = 'x') %>%
    hc_title(
      text =  paste("Time series (TS) vs matrix profile (MP) <br> window = [", window, 
                    "]  (one observation every 15 min) equivalent to ", day,
                    "day(s) and", hours, "hour(s)" ),
      margin = 20,
      align = "left",
      style = list(useHTML = TRUE)
    )
  
  htmlwidgets::saveWidget(widget = hc, file = gsub(" ", "", paste("./Plot",  j ,".html")))
  
}


result_list_av = list()
window_vector = c(96)

i=1
mp <- tsmp(df2$Power_total, window_size = window)

par(mfrow=c(4,1), cex=0.2)
plot(mp$mp,  type = "l")
plot(mp$data[[1]],  type = "l")
plot(mp$mp,  type = "l")
plot(mp1$mp,  type = "l")



mp$av <- df2$AV[c(1:length(mp$mp) )]
class(mp) <- tsmp:::update_class(class(mp), "AnnotationVector")
mp1 <- tsmp::av_apply(mp)



par(mfrow=c(4,1), cex=0.2)
plot(mp$av,  type = "l")
plot(mp$data$ts,  type = "l")
plot(mp$mp,  type = "l")
plot(mp1$mp,  type = "l")


par(mfrow=c(3,1), cex=0.2)
plot(mp$data$ts,  type = "l")
plot(mp$av,  type = "l")
plot(mp1$mp,  type = "l")

# vith annotation vector
for (j in 1:length(window_vector)) {
  window = window_vector[j]
  
  day = trunc(window/96)
  hours = (window/96 - trunc(window/96) ) *24
  
  for (i in 1:length(subloads) ) {
    #result_list[[i]] <- compute(df2[[ subloads[i] ]], windows = window)
    
    result_list[[i]] <- tsmp(df2[[ subloads[i] ]], window_size = window)
  }
  
  # ttt <- compute(df2$Power_mechanical_room, windows = window, threshold = 1)
  # ttt <- tsmp(df2$Power_mechanical_room, window_size = window)
  # plot(ttt$data$ts, type = "l")
  # plot(ttt$mp, type = "l")
  
  names( result_list ) <- paste("MP", subloads)
  
  # highchart() %>%
  #   hc_add_series(result_list$`MP Power_total`$mp,  type = "line", name = "Power_total") %>%
  #   hc_add_series(result_list$`MP Power_data_centre`$mp,  type = "line", name = "Power_data_centre") %>%
  #   hc_add_series(result_list$`MP Power_canteen`$mp,  type = "line", name = "Power_canteen") %>%
  #   hc_add_series(result_list$`MP Power_mechanical_room`$mp,  type = "line", name = "Power_mechanical_room") %>%
  #   hc_add_series(result_list$`MP Power_dimat`$mp,  type = "line", name = "Power_dimat") %>%
  #   hc_add_series(result_list$`MP Power_bar`$mp,  type = "line", name = "Power_bar") %>%
  #   hc_add_series(result_list$`MP Power_rectory`$mp,  type = "line", name = "Power_rectory") %>%
  #   hc_add_series(result_list$`MP Power_print_shop`$mp,  type = "line", name = "Power_print_shop") 
  # 
  # highchart() %>%
  #   hc_add_series(result_list$`MP Power_total`$data$ts,  type = "line", name = "Power_total") %>%
  #   hc_add_series(result_list$`MP Power_data_centre`$data$ts,  type = "line", name = "Power_data_centre") %>%
  #   hc_add_series(result_list$`MP Power_canteen`$data$ts,  type = "line", name = "Power_canteen") %>%
  #   hc_add_series(result_list$`MP Power_mechanical_room`$data$ts,  type = "line", name = "Power_mechanical_room") %>%
  #   hc_add_series(result_list$`MP Power_dimat`$data$ts,  type = "line", name = "Power_dimat") %>%
  #   hc_add_series(result_list$`MP Power_bar`$data$ts,  type = "line", name = "Power_bar") %>%
  #   hc_add_series(result_list$`MP Power_rectory`$data$ts,  type = "line", name = "Power_rectory") %>%
  #   hc_add_series(result_list$`MP Power_print_shop`$data$ts,  type = "line", name = "Power_print_shop") 
  
  
  
  options(highcharter.theme = hc_theme_smpl(tooltip = list(valueDecimals = 2)))
  
  ts_data<- ts(
    data.frame( total = result_list$`MP Power_total`$data[[1]], 
                mechanical_room  = result_list$`MP Power_mechanical_room`$data[[1]],
                bar  = result_list$`MP Power_bar`$data[[1]])
  )
  
  ts_mp<- ts(
    data.frame( total = result_list$`MP Power_total`$mp, 
                mechanical_room = result_list$`MP Power_mechanical_room`$mp,
                bar = result_list$`MP Power_bar`$mp)
  )
  
  x <- cbind(
    ts_data,
    ts_mp
  )
  
  
  hc <- hchart( x )  %>%
    highcharter::hc_chart(zoomType = 'x') %>%
    hc_title(
      text =  paste("Time series (TS) vs matrix profile (MP) <br> window = [", window, 
                    "]  (one observation every 15 min) equivalent to ", day,
                    "day(s) and", hours, "hour(s)" ),
      margin = 20,
      align = "left",
      style = list(useHTML = TRUE)
    )
  
  htmlwidgets::saveWidget(widget = hc, file = gsub(" ", "", paste("./Plot",  j ,".html")))
  
}








