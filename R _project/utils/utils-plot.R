#' @name plot_sequence
#'
#' @title Plots MP related charts with annotations
#' @ description permits to plot different king of plots useful for the Matrix Profile inspection. It permits
#' to visualize sub-sequences on the original data as well as motif and discords in the matrix profile.
#' Useful to visualize right and left MP and nearest neighbor of a given sub-sequence
#'
#' @param type the type of plot we want to see. The possible options are \code{raw}, \code{data} and \code{mp}
#' @param dataset dataset containing the variable to plot
#' @param x,y name as string of the variable to plot
#' @param x_lab,y_lab string of the corresponding axis label. Defaulted to NULL
#' @param ymax_mp maximum value of matrix profile, requested for scale comparison if multiple MP are visualized
#' @param mp_index matrix profile index to plot the vertical lined
#' @param w matrix profile window to plot the boxes
#' @param seq_index,seq_color  index and color of the reference sub-sequence
#' @param seq_nn,nn_color  index and color of the nearest neighbor sub-sequence
#' @param annotate_mp whether or not the matrix profile has to be annotated
#'
#' @return A ggplot figure.
#'
#' @noRd

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
                          seq_nn = NULL,
                          annotate_mp = FALSE,
                          seq_color = "green",
                          nn_color = "blue")
{
  fontsize <- 11
  linesize <- 0.5
  alpha <- 0.5
  
  
  plot <- ggplot(dataset, aes_string(x = x, y = y)) +
    geom_line() +
    theme_classic() +
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
    # in this case draw sequence rectangles starting in the index
    plot <- plot +
      # sub-sequence
      annotate(
        "rect",
        xmin = dataset[[x]][seq_index],
        xmax = dataset[[x]][seq_index + w],
        ymin = 0,
        ymax = max(dataset[[y]]),
        alpha = alpha,
        fill = seq_color
      ) +
      # nearest neighbor
      annotate(
        "rect",
        xmin = dataset[[x]][seq_nn],
        xmax = dataset[[x]][seq_nn + w],
        ymin = 0,
        ymax = max(dataset[[y]]),
        alpha = alpha,
        fill = nn_color
      )
    
  }
  else if (type == "mp") {
    # in this case draw a line
    plot <- plot +
      # sub-sequence
      geom_vline(xintercept = dataset[[x]][seq_index],
                 color = seq_color,
                 size = linesize) +
      # nearest neighbor
      geom_vline(xintercept = dataset[[mp_index]][seq_index],
                 color = nn_color,
                 size = linesize) +
      scale_y_continuous(limits = c(0, ymax_mp))
    
    # adds annotation if requested 
    if (annotate_mp == TRUE) {
      plot <- plot +
        labs(
          title = paste(
            "<span align='center' style='font-size:11pt'>
      <span style='color:green;'>Sequence</span> [MP, MP_index] = [<span style='color:green;'>",
            round(dataset[[y]][seq_index] , 3) ,
            ";",
            dataset[[x]][seq_index],
            "</span>] -
      <span style='color:blue;'>1stNN</span> [MP, MP_index] = [<span style='color:blue;'>",
            round(dataset[[y]][dataset[[mp_index]][seq_index]], 3) ,
            ";",
            dataset[[mp_index]][seq_index],
            "</span>]
                         </span>"
          )
        )
    }
    
    # adds shadow boxes
    if (dataset[[mp_index]][seq_index] > dataset[[x]][seq_index]) {
      # right
      plot <- plot +
        annotate(
          "rect",
          xmin = dataset[[x]][seq_index],
          xmax = max(dataset[[x]]),
          ymin = 0,
          ymax = ymax_mp,
          alpha = alpha,
          fill = "gray"
        )
      
    } else {
      # left
      plot <- plot +
        annotate(
          "rect",
          xmin = min(dataset[[x]]),
          xmax = dataset[[x]][seq_index],
          ymin = 0,
          ymax = ymax_mp,
          alpha = alpha,
          fill = "gray"
        )
    }
  }
  
  # returns the ggplot element
  return(plot)
  
}

#' @name plot_window
#'
#' @title Plots sub-sequences
#' @description Permits to plot a given sub-sequence overlapped with the first nearest neighbor sub-sequence.
#' This information is extracted from the MP index, provided as input. It is possible to plot those sub-sequences
#' in z-normalized fashon (as the original MP does for calculation) or without normalization, with its original scale
#'
#' @param type the type of plot we want to see. The possible options are \code{pure} and \code{znorm}
#' @param dataset dataset containing the variable to plot
#' @param x,y name as string of the variable to plot
#' @param x_lab,y_lab string of the corresponding axis label. Defaulted to NULL
#' @param w matrix profile window to plot the boxes
#' @param seq_index,seq_color  index and color of the reference sub-sequence
#' @param seq_nn,nn_color  index and color of the nearest neighbor sub-sequence
#'
#' @return A ggplot figure.
#'
#' @noRd

plot_window <- function(type = "pure",
                        dataset,
                        x,
                        x_lab = NULL,
                        y,
                        y_lab = NULL,
                        w = NULL,
                        seq_index = NULL,
                        seq_nn = NULL,
                        seq_color = "green",
                        nn_color = "blue")
{
  fontsize <- 11
  linesize <- 1

  plot <- ggplot(dataset)
  
  if (type == "pure") {
    plot <- plot +
      geom_line(
        data = dataset %>% filter(index >= seq_index,
                                  index <= seq_index +  w) ,
        aes(x = c(0:w), y = data),
        color = seq_color,
        size = linesize
      ) +
      geom_line(
        data = dataset %>% filter(index >= seq_nn,
                                  index <= seq_nn +  w) ,
        aes(x = c(0:w), y = data),
        color = nn_color,
        size = linesize
      )
  } 
  else if (type == "znorm") {
    plot <- plot +
      geom_line(
        data = dataset %>% filter(index >= seq_index,
                                  index <= seq_index +  w) ,
        aes(x = c(0:w), (data - mean(data)) / sd(data)),
        color = seq_color,
        size = linesize
      ) +
      geom_line(
        data = dataset %>% filter(index >= seq_nn,
                                  index <= seq_nn +  w) ,
        aes(x = c(0:w), (data - mean(data)) / sd(data)),
        color = nn_color,
        size = linesize
      )
  }
  
  plot <- plot +
    theme_classic() +
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
    scale_x_continuous(limits = c(0, w), expand = c(0, 0)) +
    labs(x = x_lab, y = y_lab)
  
  return(plot)
  
}