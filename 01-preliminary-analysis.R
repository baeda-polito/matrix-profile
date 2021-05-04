

library(energydataset)
library(tsmp)
library(dplyr)
library(ggplot2)
library(ggpubr)
library(ggtext) 

# style definition for time series plot
style <- {theme_bw() +
    theme(
      panel.background = element_rect(fill = "white"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_text(size = 11),
      axis.title.x = element_text(
        size = 11,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.title.y = element_text(
        size = 11,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.text.x = element_text(size = 11),
      axis.text.y = element_text(size = 11)
    )}

plot_sequence <- function(type = "data", dataset, x, y, y_lab = NULL, mp_index = NULL, w, seq_index = NULL, seq_nn = NULL){
  
  plot <- ggplot(dataset, aes_string(x = x, y = y)) +
    geom_line() +
    theme_bw() +
    theme(
      plot.title = element_markdown(lineheight = 1.1),
      panel.background = element_rect(fill = "white"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_text(size = 11),
      axis.title.x = element_text(
        size = 11,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.title.y = element_text(
        size = 11,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.text.x = element_text(size = 11),
      axis.text.y = element_text(size = 11)
    )
  
  if (type == "data") {
    
    plot <- plot +
      annotate(
        "rect",
        xmin = dataset[[x]][seq_index],
        xmax = dataset[[x]][seq_index + w],
        ymin = 0,
        ymax = max(dataset[[y]]),
        alpha = .5,
        fill = "green"
      ) +
      # nearest neighbor
      annotate(
        "rect",
        xmin = dataset[[x]][seq_nn],
        xmax = dataset[[x]][seq_nn + w],
        ymin = 0,
        ymax = max(dataset[[y]]),
        alpha = .5,
        fill = "blue"
      )
    
  }
  
  if (type == "mp") {
    plot <- plot +
      geom_vline(xintercept = dataset[[x]][seq_index],
                 color = "green",
                 size = 0.5) +
      # nearest neighbor
      geom_vline(xintercept = dataset[[mp_index]][seq_nn],
                 color = "blue",
                 size = 0.5) +
      labs(x = NULL, 
           y = y_lab,
           title = paste(" **Matrix Profile**
             <span style='font-size:13pt'> 
             <span style='color:green;'>MP(Sequence)=", round(dataset[[y]][seq_index],3) ,"</span>,
             <span style='color:blue;'>MP(1st Nearest Neighbor)=", round(dataset[[y]][seq_nn],3)  ," </span>,
             </span>"
           )
      ) 
  } 
  if (type == "raw") {
    plot <- plot + labs(x = NULL, y = y_lab)
  }
  
  return(plot)
  
}

# load dataset
df <- energydataset::data_power_raw

# fix dataset names
df_univariate <- df %>%
  mutate(
    CET = as.POSIXct(CET , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
    Power_total = `1226`,
    Power_data_centre = `1045`,
    Power_canteen = `1047`,
    Power_mechanical_room = `1022`,
    Power_dimat = `294`,
    Power_bar = `1046`,
    Power_rectory = `1085`,
    Power_print_shop = `1086`
  ) %>%
  dplyr::select(-c(2:9))

# plot dataset time series
{
  p1_TS <- ggplot(df_univariate, aes(x = CET, y = Power_total)) +
    geom_line() + labs(x = NULL , y = "Total [kW]") + style
  
  p2_TS <-
    ggplot(df_univariate, aes(x = CET, y = Power_mechanical_room)) +
    geom_line() + labs(x = NULL , y = "Mechanical room [kW]") + style
  
  p3_TS <-
    ggplot(df_univariate, aes(x = CET, y = Power_data_centre)) +
    geom_line() + labs(x = NULL , y = "Data Centre [kW]") + style
  
  p4_TS <-
    ggplot(df_univariate, aes(x = CET, y = Power_canteen)) +
    geom_line() + labs(x = NULL , y = "Canteen [kW]") + style
  
  p5_TS <-
    ggplot(df_univariate, aes(x = CET, y = Power_dimat)) +
    geom_line() + labs(x = NULL , y = "DIMAT [kW]") + style
  
  p6_TS <- ggplot(df_univariate, aes(x = CET, y = Power_bar)) +
    geom_line() + labs(x = NULL , y = "Bar [kW]") + style
  
  p7_TS <-
    ggplot(df_univariate, aes(x = CET, y = Power_rectory)) +
    geom_line() + labs(x = NULL , y = "Rectory [kW]") + style
  
  p8_TS <-
    ggplot(df_univariate, aes(x = CET, y = Power_print_shop)) +
    geom_line() + labs(x = NULL , y = "Print Shop [kW]") + style
  
  dev.new()
  
  ggarrange(
    p1_TS,
    p2_TS,
    p3_TS,
    p4_TS,
    p5_TS,
    p6_TS,
    p7_TS,
    p8_TS,
    ncol = 1,
    nrow = 8,
    widths = c(3),
    align = "v"
  )
  
  ggsave("./figures/01.01-dataset.png",
         width = 10,
         height = 13)
  dev.off()
  }

# matrix profile on the total power
w = 96
# mp_univariate <- tsmp(df_univariate$Power_total, window_size = w, exclusion_zone = 0.5 )

# save(mp_univariate, file = "./data/mp_univariate_total_05ex_w96.RData")
load("./data/mp_univariate_total_05ex_w96.RData")

# define length of mp
mp_length = length(mp_univariate$mp)

df_mp_univariate <- data.frame(
  data = df_univariate$Power_total[c(1:mp_length)],
  data_index = df_univariate$CET[c(1:mp_length)],
  index = as.integer(rownames(df_univariate)[c(1:mp_length)]),
  mp = mp_univariate[[1]],
  mp_index = mp_univariate[[2]],
  rmp = mp_univariate[[3]],
  rmp_index = mp_univariate[[4]],
  lmp = mp_univariate[[5]],
  lmp_index = mp_univariate[[6]]
)


# plot matrix profile
{
  mplimity <- 15
  
  p0data <- plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "data_index",
    y = "data",
    y_lab = "Total [kW]",
    w = 96,
    seq_index = 5000,
    seq_nn = 1000
  )
  
  p1mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    y = "mp",
    y_lab = "MP",
    w = 96,
    seq_index = 5000,
    seq_nn = 1000
  )
  
  p2mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    y = "rmp",
    y_lab = "RMP",
    w = 96,
    seq_index = 5000,
    seq_nn = 1000
  )
  
  p3mp <-  plot_sequence(
    type = "raw",
    df_mp_univariate,
    x = "index",
    y = "lmp",
    y_lab = "LMP",
    w = 96,
    seq_index = 5000,
    seq_nn = 1000
  )
  
  
  dev.new()
  
  ggarrange(
    p0data,
    p1mp,
    p2mp,
    p3mp,
    ncol = 1,
    nrow = 4,
    widths = c(3),
    align = "v"
  )
  
  ggsave("./figures/01.02-total-MP.png",
         width = 10,
         height = 7)
  dev.off()
  
}

############################################ find discord
discord <- find_discord(mp_univariate,
                        n_discords = 1,
                        n_neighbors = 1)

# discord index
discord_index <- as.numeric(discord$discord$discord_idx)

# first nn index
discord_n1_index <- as.numeric(discord$discord$discord_neighbor[[1]])

# plot discord
{
  # time series plot and sequence identification
  p0data_discord <-  plot_sequence(
    type = "data",
    df_mp_univariate,
    x = "data_index",
    y = "data",
    y_lab = "Power [kW]",
    w = 96,
    seq_index = discord_index,
    seq_nn = discord_n1_index
  )
  
  p1mp_discord <-  plot_sequence(
    type = "mp",
    df_mp_univariate,
    x = "index",
    y = "mp",
    y_lab = "MP",
    mp_index = "mp_index",
    w = 96,
    seq_index = discord_index,
    seq_nn = discord_n1_index
  )
  
  p2mp_discord <-  plot_sequence(
    type = "mp",
    df_mp_univariate,
    x = "index",
    y = "rmp",
    y_lab = "RMP",
    mp_index = "rmp_index",
    w = 96,
    seq_index = discord_index,
    seq_nn = discord_n1_index
  )
  
  p3mp_discord <-   plot_sequence(
    type = "mp",
    df_mp_univariate,
    x = "index",
    y = "lmp",
    y_lab = "LMP",
    mp_index = "lmp_index",
    w = 96,
    seq_index = discord_index,
    seq_nn = discord_n1_index
  )
  
  dev.new()
  
  ggarrange(
    p0data_discord,
    p1mp_discord,
    p2mp_discord,
    p3mp_discord,
    ncol = 1,
    nrow = 4,
    widths = c(3),
    align = "v"
  )
  
  ggsave("./figures/01.03-total-MP-discord.png",
         width = 10,
         height = 7)
  dev.off()
  }

# plot discord profiles normal and normalized
{
  pmp_discord_pure <- ggplot() +
    geom_line(
      data = df_mp_univariate %>% filter(index >= discord_index,
                                         index <= discord_index +  w) ,
      aes(x = c(0:w), y = data),
      color = "green",
      size = 1.5
    ) +
    geom_line(
      data = df_mp_univariate %>% filter(index >= discord_n1_index,
                                         index <= discord_n1_index +  w) ,
      aes(x = c(0:w), y = data),
      color = "blue",
      size = 1.5
    ) +
    labs(x = NULL , y = "Power [kW]") + style
  
  pmp_discord_z <- ggplot() +
    geom_line(
      data = df_mp_univariate %>% filter(index >= discord_index,
                                         index <= discord_index +  w) ,
      aes(x = c(0:w), y = (data - mean(data)) / sd(data)),
      color = "green",
      size = 1.5
    ) +
    geom_line(
      data = df_mp_univariate %>% filter(index >= discord_n1_index,
                                         index <= discord_n1_index +  w) ,
      aes(x = c(0:w), y = (data - mean(data)) / sd(data)),
      color = "blue",
      size = 1.5
    ) +
    labs(x = NULL , y = "Power [z-score]") + style
  
  dev.new()
  
  ggarrange(
    pmp_discord_pure,
    pmp_discord_z,
    ncol = 1,
    nrow = 2,
    widths = c(3),
    align = "v"
  )
  
  ggsave(
    "./figures/01.04-total-MP-discord-profile.png",
    width = 10,
    height = 7
  )
  dev.off()
}

############################################ find motif
motif <- find_motif(mp_univariate,
                    n_motifs  = 1,
                    n_neighbors = 1)

# motif index
motif_index <- as.numeric(motif$motif$motif_idx[[1]][1])

# first nn index
motif_n1_index <- as.numeric(motif$motif$motif_neighbor[[1]])

# plot motif
{
  motif_df <- data.frame(
    data_index = c(
      df_mp_univariate$data_index[motif_index],
      df_mp_univariate$data_index[motif_n1_index + w]
    ),
    data = c(max(df_mp_univariate$data),
             max(df_mp_univariate$data)) - 50,
    label = c("Motif", "1st NN")
    
  )
  
  p0data_motif <-
    ggplot(df_mp_univariate, aes(x = data_index, y = data)) +
    geom_line() + labs(x = NULL , y = "Total [kW]") + style +
    # motif
    annotate(
      "rect",
      xmin = df_mp_univariate$data_index[motif_index],
      xmax = df_mp_univariate$data_index[motif_index + w],
      ymin = 0,
      ymax = max(df_mp_univariate$data),
      alpha = .5,
      fill = "green"
    ) +
    # nearest neighbor
    annotate(
      "rect",
      xmin = df_mp_univariate$data_index[motif_n1_index],
      xmax = df_mp_univariate$data_index[motif_n1_index + w],
      ymin = 0,
      ymax = max(df_mp_univariate$data),
      alpha = .5,
      fill = "blue"
    ) +
    geom_label(data = motif_df, aes(label = label))
  
  
  p1mp_motif <-
    ggplot(df_mp_univariate, aes(x = index, y = mp)) +
    geom_line() + labs(x = NULL , y = "MP ") + style +
    scale_x_continuous(limits = c(0, max(df_mp_univariate$index)),
                       breaks = seq(0, max(df_mp_univariate$index), by = 1000)) +
    scale_y_continuous(limits = c(0, mplimity)) +
    # motif
    annotate(
      "rect",
      xmin = motif_index,
      xmax = motif_index + w,
      ymin = 0,
      ymax = mplimity,
      alpha = .5,
      fill = "green"
    ) +
    # nearest neighbor
    annotate(
      "rect",
      xmin = motif_n1_index,
      xmax = motif_n1_index + w,
      ymin = 0,
      ymax = mplimity,
      alpha = .5,
      fill = "blue"
    )
  
  
  
  p2mp_motif <-
    ggplot(df_mp_univariate, aes(x = index, y = rmp)) +
    geom_line() +  labs(x = NULL , y = "RMP ") + style +
    scale_x_continuous(limits = c(0, max(df_mp_univariate$index)),
                       breaks = seq(0, max(df_mp_univariate$index), by = 1000)) +
    scale_y_continuous(limits = c(0, mplimity)) +
    # motif
    annotate(
      "rect",
      xmin = motif_index,
      xmax = motif_index + w,
      ymin = 0,
      ymax = mplimity,
      alpha = .5,
      fill = "green"
    ) +
    # nearest neighbor
    annotate(
      "rect",
      xmin = motif_n1_index,
      xmax = motif_n1_index + w,
      ymin = 0,
      ymax = mplimity,
      alpha = .5,
      fill = "blue"
    )
  
  
  p3mp_motif <-
    ggplot(df_mp_univariate, aes(x = index, y = lmp)) +
    geom_line() +  labs(x = NULL , y = "LMP") + style +
    scale_x_continuous(limits = c(0, max(df_mp_univariate$index)),
                       breaks = seq(0, max(df_mp_univariate$index), by = 1000)) +
    scale_y_continuous(limits = c(0, mplimity)) +
    # motif
    annotate(
      "rect",
      xmin = motif_index,
      xmax = motif_index + w,
      ymin = 0,
      ymax = mplimity,
      alpha = .5,
      fill = "green"
    ) +
    # nearest neighbor
    annotate(
      "rect",
      xmin = motif_n1_index,
      xmax = motif_n1_index + w,
      ymin = 0,
      ymax = mplimity,
      alpha = .5,
      fill = "blue"
    )
  
  
  dev.new()
  
  ggarrange(
    p0data_motif,
    p1mp_motif,
    p2mp_motif,
    p3mp_motif,
    ncol = 1,
    nrow = 4,
    widths = c(3),
    align = "v"
  )
  
  ggsave("./figures/01.03-total-MP-motif.png",
         width = 10,
         height = 7)
  dev.off()
}

# plot motif profiles normal and normalized
{
  pmp_motif_pure <- ggplot() +
    geom_line(
      data = df_mp_univariate %>% filter(index >= motif_index,
                                         index <= motif_index +  w) ,
      aes(x = c(0:w), y = data),
      color = "green",
      size = 1.5
    ) +
    geom_line(
      data = df_mp_univariate %>% filter(index >= motif_n1_index,
                                         index <= motif_n1_index +  w) ,
      aes(x = c(0:w), y = data),
      color = "blue",
      size = 1.5
    ) +
    labs(x = NULL , y = "Power [kW]") + style
  
  pmp_motif_z <- ggplot() +
    geom_line(
      data = df_mp_univariate %>% filter(index >= motif_index,
                                         index <= motif_index +  w) ,
      aes(x = c(0:w), y = (data - mean(data)) / sd(data)),
      color = "green",
      size = 1.5
    ) +
    geom_line(
      data = df_mp_univariate %>% filter(index >= motif_n1_index,
                                         index <= motif_n1_index +  w) ,
      aes(x = c(0:w), y = (data - mean(data)) / sd(data)),
      color = "blue",
      size = 1.5
    ) +
    labs(x = NULL , y = "Power [z-score]") + style
  
  dev.new()
  
  ggarrange(
    pmp_motif_pure,
    pmp_motif_z,
    ncol = 1,
    nrow = 2,
    widths = c(3),
    align = "v"
  )
  
  ggsave(
    "./figures/01.04-total-MP-motif-profile.png",
    width = 10,
    height = 7
  )
  dev.off()
}
