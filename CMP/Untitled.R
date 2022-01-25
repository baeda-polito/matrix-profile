#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # clears the console
rm(list = ls())             # remove all variables of the workspace
source("global_vars.R")
source("utils_functions.R")
source("calendarHeat.R")



context_string <- c(
  "ctx_from00_00_to01_00_m05_15",
  "ctx_from05_15_to06_15_m02_30",
  "ctx_from07_45_to08_45_m06_45",
  "ctx_from14_30_to15_30_m03_30",
  "ctx_from18_00_to19_00_m05_00"
)
for (context_id in c(1:5)) {
  df <- data.frame()
  for (cluster_id in c(1:5)) {
    df_tmp <-
      read.csv(file.path(
        "Polito_Usecase",
        "data",
        context_string[context_id],
        paste0("anomaly_results_Cluster_", cluster_id, ".csv")
      )) %>%
      mutate(Cluster = cluster_id)
    
    df <- rbind(df, df_tmp)
    
  }
  
  df <- df %>%
    dplyr::arrange(Date) %>%
    dplyr::mutate(severity = cmp_score + energy_score)
  
  
  dev.new()
  
  png(
    filename = file.path(
      "Polito_Usecase",
      "figures",
      paste0("calendar_result_context_",
        context_id, ".png")
      
    ),
    res = 200,
    width = 1800,
    height = 700
  )
  
  print({
    
  extra.calendarHeat(
    dates =  df$Date,
    values = df$severity,
    pvalues = df$Cluster,
    pch.symbol = c(0:5),
    cex.symbol = 1,
    #col.symbol='gray50',
    color = 'r2r'
  )
  })
  
  dev.off()
  
}
