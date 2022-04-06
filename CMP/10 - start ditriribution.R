#  LOAD PACKAGES and FUNCTIONS ------------------------------------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("global_vars.R")     # Loads global variables
source("utils_functions.R") # Loads utils functions

library(dplyr)
library(ggplot2)
# load the context decoder dataframe
df <-
  read.csv(file.path("Polito_Usecase", "diagnosis", "diagnosis_final.csv")) 


# SECTION ------------------------------------
severity_vector <- c(4:10)





df_ww <- data.frame(
  
  percent = round(c(
    
    
    42.300619,
    32.279227,
    13.099643,
    12.046538,
    54.282605,
    29.050103,
    8.474385,
    7.918934,
    50.815538,
    32.191406,
    8.523175,
    8.195909,
    55.886658,
    33.350347,
    5.377369,
    5.111653,
    64.726590,
    17.733909,
    10.136986,
    7.128542)/100,2),
  
  
  
  start = as.integer(c(
    0.0,
    3.0,
    2.0,
    1.0,
    0.0,
    3.0,
    2.0,
    1.0,
    0.0,
    3.0,
    2.0,
    1.0,
    3.0,
    0.0,
    1.0,
    2.0,
    3.0,
    0.0,
    2.0,
    1.0)+1),
  
  
  context = c(
    "Context 1",
    "Context 1",
    "Context 1",
    "Context 1",
    "Context 2",
    "Context 2",
    "Context 2",
    "Context 2",
    "Context 3",
    "Context 3",
    "Context 3",
    "Context 3",
    "Context 4",
    "Context 4",
    "Context 4",
    "Context 4",
    "Context 5",
    "Context 5",
    "Context 5",
    "Context 5")
  
)


plot <- ggplot(data=df_ww, 
  aes(x=start, y=percent, fill = as.factor(start),
    label = scales::percent(percent)), 
  color = "grey50") +
  geom_bar(stat="identity")+
  scale_y_continuous(labels = scales::percent)+

  facet_wrap(vars(context), ncol = 5)+
  labs(#title = "Daily Profile Cluster Results",
    #subtitle = "Identification of 6 similarity groups for CMP analysis",
    x = "Start position of best matching subsequences",
    y = "Percentage [%]") +
  theme_minimal() +
  scale_fill_manual(values = palette ) +
  geom_text(nudge_y= .03,
    family = font_family,
    size = 3)+


  ggplot2::theme(
    text = element_text(family = font_family),
    axis.ticks = element_line(colour = "black"),
    #panel.grid = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    axis.line.y = element_line(colour = "black"),
    axis.line.x = element_line(colour = "black"),
    
    plot.title = element_text(
      hjust = 0.5,
      size = fontsize_large,
      margin = margin(
        t = 0,
        r = 0,
        b = 0,
        l = 0
      ),
      
    ),
    plot.subtitle = element_text(
      hjust = 0.5,
      size = fontsize_small,
      margin = margin(
        t = 5,
        r = 5,
        b = 10,
        l = 10
      )
    ),
    # legend
    legend.position = "none",
    # legend position on the top of the graph
    # strip.text = element_text(size = 17), # facet wrap title fontsize
    # AXIS X
    #axis.title.x = element_text(size = fontsize_medium, margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.x = element_text(
      size = fontsize_small,
      margin = margin(
        t = 5,
        r = 5,
        b = 5,
        l = 5
      ),
      angle = 0,
      vjust = .3
    ),
    # AXIS Y
    #axis.title.y = element_text(size = fontsize_medium,margin = margin(t = 20, r = 20, b = 0, l = 0)),
    axis.text.y = element_text(
      size = fontsize_small,
      margin = margin(
        t = 5,
        r = 5,
        b = 0,
        l = 5
      ),
      angle = 0,
      vjust = .3
    ),
    # background
    # panel.background = element_rect(fill = "gray99"),# background of plotting area, drawn underneath plot
    # panel.grid.major = element_blank(),            # draws nothing, and assigns no space.
    # panel.grid.minor = element_blank(),
    # draws nothing, and assigns no space.
    plot.margin = unit(c(
      plot_margin, plot_margin, plot_margin, plot_margin
    ), "cm")
  )



figures_path <- file.path("Polito_Usecase", "figures")

dev.new()

plot
ggsave(
  filename = file.path(figures_path, "context_percentage.jpg"),
  width = 10,
  height = 3,
  dpi = dpi,
  bg = background_fill
)
dev.off()


  



