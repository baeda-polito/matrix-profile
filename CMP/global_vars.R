# global variables
# 

# windowsFonts("Georgia" = windowsFont("Georgia"))


global_vars_df <- read.csv(file.path(getwd(), "Polito_Usecase", "data", "global_variables.csv"), 
                           sep = ',', dec = ".")

font_family <-  global_vars_df$variable[global_vars_df$variable_name == "font_family"]
fontsize_large <- as.integer( global_vars_df$variable[global_vars_df$variable_name == "fontsize_large"])
fontsize_medium <- as.integer( global_vars_df$variable[global_vars_df$variable_name == "fontsize_medium"])
fontsize_small <- as.integer( global_vars_df$variable[global_vars_df$variable_name == "fontsize_small"])
fontsize_smaller <- as.integer( global_vars_df$variable[global_vars_df$variable_name == "fontsize_smaller"])
background_fill <- global_vars_df$variable[global_vars_df$variable_name == "background_fill"]
linesize <- as.integer( global_vars_df$variable[global_vars_df$variable_name == "line_size"])


dpi <-  as.integer(global_vars_df$variable[global_vars_df$variable_name == "dpi_resolution"])
palette <- rev(c('#d53e4f','#f46d43','#fdae61','#fee08b','#ffffbf','#e6f598','#abdda4','#66c2a5','#3288bd'))
# palette <- RColorBrewer::brewer.pal(9, "RdYlGn")
# palette <- rev(RColorBrewer::brewer.pal(11,"RdYlBu"))
# palette <- viridis::viridis(20)
plot_margin <-  0.5
