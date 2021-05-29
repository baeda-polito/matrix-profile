plot_sequence <- function(type = "data",
                          dataset,
                          x,
                          x_lab = NULL,
                          y,
                          y_lab = NULL,
                          ymax_mp = NULL,
                          mp_index = NULL,
                          w = NULL,
                          seq_index = NULL,
                          seq_nn = NULL
) 
{
  fontsize <- 11
  seq_color <- "green"
  nn_color <- "blue"
  
  plot <- ggplot(dataset, aes_string(x = x, y = y)) +
    geom_line() +
    theme_bw() +
    theme(
      plot.title = element_markdown(lineheight = 1.1),
      panel.background = element_rect(fill = "white"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_text(size = fontsize),
      axis.title.x = element_text(
        size = fontsize,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.title.y = element_text(
        size = fontsize,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.text.x = element_text(size = fontsize),
      axis.text.y = element_text(size = fontsize)
    ) + 
    labs(x = x_lab, y = y_lab)
  
  if (type == "data") {
    # in this case draw sequence rectabgle starting in the index
    plot <- plot +
      annotate(
        "rect",
        xmin = dataset[[x]][seq_index],
        xmax = dataset[[x]][seq_index + w],
        ymin = 0,
        ymax = max(dataset[[y]]),
        alpha = .5,
        fill = seq_color
      ) +
      # nearest neighbor
      annotate(
        "rect",
        xmin = dataset[[x]][seq_nn],
        xmax = dataset[[x]][seq_nn + w],
        ymin = 0,
        ymax = max(dataset[[y]]),
        alpha = .5,
        fill = nn_color
      ) 
    
  }
  
  if (type == "mp") {
    # in this case draw a line
    plot <- plot +
      geom_vline(xintercept = dataset[[x]][seq_index],
                 color = seq_color,
                 size = 0.5) +
      # nearest neighbor
      geom_vline(xintercept = dataset[[mp_index]][seq_index],
                 color = nn_color,
                 size = 0.5) +
      scale_y_continuous(limits = c(0, ymax_mp )) +
      labs(title = paste("<span align='center' style='font-size:11pt'>
      <span style='color:green;'>Sequence</span> [MP, MP_index] = [<span style='color:green;'>",round( dataset[[y]][seq_index] ,3) ,";", dataset[[x]][seq_index], "</span>] -
      <span style='color:blue;'>1stNN</span> [MP, MP_index] = [<span style='color:blue;'>",round(dataset[[y]][dataset[[mp_index]][seq_index]  ],3) ,";", dataset[[mp_index]][seq_index], "</span>] 
                         </span>"
      ))
    
    if (dataset[[mp_index]][seq_index] > dataset[[x]][seq_index] ) { # right
      plot <- plot + 
        annotate("rect", 
                 xmin = dataset[[x]][seq_index], 
                 xmax = max( dataset[[x]]),
                 ymin = 0, 
                 ymax = ymax_mp,
                 alpha = .3,fill = "gray")
      
    } else { # left
      plot <- plot + 
        annotate("rect", 
                 xmin = min( dataset[[x]]),
                 xmax = dataset[[x]][seq_index], 
                 ymin = 0, 
                 ymax = ymax_mp,
                 alpha = .3,fill = "gray")
    }
    
    
    
    
  } 
  
  return(plot)
  
}


plot_window <- function(type = "pure",
                        dataset,
                        x,
                        x_lab = NULL,
                        y,
                        y_lab = NULL,
                        w = NULL,
                        seq_index = NULL,
                        seq_nn = NULL
) 
{
  fontsize <- 11
  linesize <- 1
  seq_color <- "green"
  nn_color <- "blue"
  
  
  plot <- ggplot(dataset) 
  
  if (type == "pure") {
    plot <- plot + 
      geom_line(
      data = dataset %>% filter(index >= seq_index,
                                index <= seq_index +  w) ,
      aes(x = c(0:w), y = data),
      color = "green",
      size = linesize
    ) +
      geom_line(
        data = dataset %>% filter(index >= seq_nn,
                                  index <= seq_nn +  w) ,
        aes(x = c(0:w), y = data),
        color = "blue",
        size = linesize
      ) 
  } else if (type == "znorm") {
    
    plot <- plot + 
      geom_line(
        data = dataset %>% filter(index >= seq_index,
                                  index <= seq_index +  w) ,
        aes(x = c(0:w), (data - mean(data)) / sd(data)),
        color = "green",
        size = linesize
      ) +
      geom_line(
        data = dataset %>% filter(index >= seq_nn,
                                  index <= seq_nn +  w) ,
        aes(x = c(0:w), (data - mean(data)) / sd(data)),
        color = "blue",
        size = linesize
      ) 
  }
    
  plot <- plot + 
    theme_bw() +
    theme(
      plot.title = element_markdown(lineheight = 1.1),
      panel.background = element_rect(fill = "white"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_text(size = fontsize),
      axis.title.x = element_text(
        size = fontsize,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.title.y = element_text(
        size = fontsize,
        margin = margin(
          t = 1,
          r = 1,
          b = 0,
          l = 0,
          unit = "mm"
        )
      ),
      axis.text.x = element_text(size = fontsize),
      axis.text.y = element_text(size = fontsize)
    ) + 
    scale_x_continuous(limits = c(0, w ), expand = c(0,0)) +
    labs(x = x_lab, y = y_lab)
  
  return(plot)
  
}