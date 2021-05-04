library(shiny)
library(energydataset)
library(tsmp)
library(dplyr)
library(ggplot2)
library(ggpubr)

ui <- fluidPage(
  uiOutput("slider"),
  plotOutput("plot", height = "650px", width = "100%")
  
)

server <- function(input, output, session) {
  
  actual_color <- "green"
  nearest_color <- "blue"
  
  
 
  # 
  # 
  # df_mp_pure <- read.csv("./data/mp_pure.csv")
  # 
  # df_data <- read.csv("./data/df.csv")[1:3745,] %>%
  #   dplyr::mutate(Timestamp = as.POSIXct(Timestamp , format = "%Y-%m-%d %H:%M:%S" , tz = "GMT"),
  #                 Power = X1226) %>%
  #   dplyr::select(-X1226)
  
  # yy <- aamp(df_data$Power, window_size  = 96)
  # df <- energydataset::data_power_raw
  # 
  # df_univariate <- df %>%
  #   mutate(Timestamp = as.POSIXct(CET , format = "%Y-%m-%d %H:%M:%S" , tz = "CET")) %>%
  #   filter( Timestamp >= "2015-05-01 00:00:00.0", Timestamp < "2015-06-10 00:00:00.0") %>%
  #   select(Timestamp, "1226")
  # 
  # write.table(df_univariate, file="./data_comparison.csv", quote=F,sep=",",row.names=F)

  
  w = 96
  # mp_univariate <- tsmp(df_univariate$`1226`, window_size = w, exclusion_zone = 0.2 )
  # 
  # # find discord
  # discord <- find_discord(mp_univariate,
  #                         n_discords = 1,
  #                         n_neighbors = 1
  # )
  # discord_index <- as.numeric(discord$discord$discord_idx)
  # discord_n1_index <- as.numeric(discord$discord$discord_neighbor[[1]])
  # 
  # discord_df <- data.frame(
  #   data_index = c(df_mp_univariate$data_index[discord_index],
  #                  df_mp_univariate$data_index[discord_n1_index+w]
  #   ),
  #   data = c(max(df_mp_univariate$data),
  #            max(df_mp_univariate$data)
  #   )-50,
  #   label = c("Discord", "1st NN")
  # 
  # )
  # 
  # mp_length = length(mp_univariate$mp)
  # 
  # df_mp_univariate <- data.frame(
  #   data = df_univariate$`1226`[c(1:mp_length)],
  #   data_index = df_univariate$Timestamp[c(1:mp_length)],
  #   index =as.integer(rownames(df_univariate)[c(1:mp_length)]),
  #   mp = mp_univariate[[1]],
  #   mp_index = mp_univariate[[2]],
  #   rmp = mp_univariate[[3]],
  #   rmp_index = mp_univariate[[4]],
  #   lmp = mp_univariate[[5]],
  #   lmp_index = mp_univariate[[6]]
  # )
  # 
  # 
  # save(df_mp_univariate, file = "df_mp_univariate.RData")
  load("df_mp_univariate.RData")
  

  df_mp_pure <- read.csv("./data/mp_pure.csv")
  colnames(df_mp_pure) <- c("index", "mp_pure", "mp_pure_index", "lmp_index","rmp_index" )
  df_mp_univariate <- cbind(df_mp_univariate, df_mp_pure[, c(2:3)] )
  
  output$slider <- renderUI({
    sliderInput("slider", "Index", 
                 value = 96, 
                 min = 0, max = dim(df_mp_univariate)[1], 
                 step = 24, width = "100%")
  })
  
  output$plot <- renderCachedPlot({
    
    req(input$slider)
    # plot original time series
    
    p1 <- {
      ggplot(df_mp_univariate, aes( x = data_index, y= data)) + 
        geom_line( ) + 
        labs( x = NULL , y = "Power [kW]") + 
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        )+
        # discord
        annotate("rect", 
                 xmin = df_mp_univariate$data_index[input$slider], 
                 xmax = df_mp_univariate$data_index[input$slider+w], 
                 ymin = 0, 
                 ymax = max(df_mp_univariate$data),
                 alpha = .5,fill = actual_color) +
        # nearest neighbor
        annotate("rect", 
                 xmin = df_mp_univariate$data_index[df_mp_univariate$mp_index[ input$slider]], 
                 xmax = df_mp_univariate$data_index[df_mp_univariate$mp_index[ input$slider]+w], 
                 ymin = 0, 
                 ymax = max(df_mp_univariate$data),
                 alpha = .5,fill = nearest_color) +
        # nearest neighbor
        annotate("rect", 
                 xmin = df_mp_univariate$data_index[df_mp_univariate$mp_pure_index[ input$slider]], 
                 xmax = df_mp_univariate$data_index[df_mp_univariate$mp_pure_index[ input$slider]+w], 
                 ymin = 0, 
                 ymax = max(df_mp_univariate$data),
                 alpha = .5, fill = "red") 
    }
    
    # plot matrix profile
    p2 <- {
      ggplot( df_mp_univariate, aes(  x = index, y = mp)) + 
        geom_line( ) + 
        labs( x = NULL , y = "MP Z-score") + 
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        )+
        scale_x_continuous(limits = c(0, max(df_mp_univariate$index) ), 
                           breaks = seq(0, max(df_mp_univariate$index), by = 500) 
        ) +
        scale_y_continuous(limits = c(0, 15 )) +
        # discord
        geom_vline(xintercept = df_mp_univariate$index[ input$slider ],
                   color = actual_color,
                   size = 0.5) +
        # nearest neighbor
        geom_vline(xintercept = df_mp_univariate$mp_index[ input$slider ],
                   color = nearest_color,
                   size = 0.5) +
        geom_label(data = data.frame( index = df_mp_univariate$index[input$slider],
                                      mp = 8, 
                                      label =  round( df_mp_univariate$mp[input$slider],2)),
                   aes(label = label), color = "black", size = 5, fontface = "bold")
    }
    
    # plot RIGTH matrix profile
    p3 <- {
      ggplot(df_mp_univariate, aes(x = index, y = rmp)) +
        geom_line() +
        labs(x = NULL , y = "R-MP (Z-score)") +
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        )+
        scale_x_continuous(limits = c(0, max(df_mp_univariate$index) ), 
                           breaks = seq(0, max(df_mp_univariate$index), by = 500) 
        ) +
        scale_y_continuous(limits = c(0, 15 )) +
        # see on rigth
        annotate("rect", 
                 xmin = df_mp_univariate$index[ input$slider ], 
                 xmax = dim(df_mp_univariate)[1],
                 ymin = 0, 
                 ymax = max(df_mp_univariate$rmp),
                 alpha = .3,fill = "gray") +
        # discord
        geom_vline(xintercept = df_mp_univariate$index[ input$slider ],
                   color = actual_color,
                   size = 0.5) +
        # nearest neighbor
        geom_vline(xintercept = df_mp_univariate$rmp_index[ input$slider ],
                   color = nearest_color,
                   size = 0.5)+
        geom_label(data = data.frame( index = df_mp_univariate$index[input$slider],
                                      rmp = 12, 
                                      label =  round( df_mp_univariate$rmp[input$slider],2)),
                   aes(label = label), color = "black", size = 5, fontface = "bold")
    }
    
    # plot LEFT matrix profile
    p4 <- {
      ggplot( df_mp_univariate, aes(  x = index, y = lmp)) + 
      geom_line( ) + 
      labs( x = "Index" , y = "L-MP (Z-score)") + 
      theme_bw() +
      theme(panel.background = element_rect(fill = "white"),
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            legend.title = element_text(size = 13),
            axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
            axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
            axis.text.x = element_text(size = 13),
            axis.text.y = element_text(size = 13)
      )+
      scale_x_continuous(limits = c(0, max(df_mp_univariate$index) ), 
                         breaks = seq(0, max(df_mp_univariate$index), by = 500) 
      ) +
      scale_y_continuous(limits = c(0, 15 )) +
      # see on left
      annotate("rect", 
               xmin = 0, 
               xmax = df_mp_univariate$index[ input$slider ], 
               ymin = 0, 
               ymax = max(df_mp_univariate$lmp),
               alpha = .3,fill = "gray") +
      # discord
      geom_vline(xintercept = df_mp_univariate$index[ input$slider ],
                 color = actual_color,
                 size = 0.5) +
      # nearest neighbor
      geom_vline(xintercept = df_mp_univariate$lmp_index[ input$slider ],
                 color = nearest_color,
                 size = 0.5) +
      geom_label(data = data.frame( index = df_mp_univariate$index[input$slider],
                                    lmp = 12, 
                                    label =  round( df_mp_univariate$lmp[input$slider],2)),
                 aes(label = label), color = "black", size = 5, fontface = "bold")
      }
    
    # plot matrix profile
    p5 <- {
      ggplot( df_mp_univariate, aes(  x = index, y = mp_pure)) + 
        geom_line( ) + 
        labs( x = NULL , y = "MP (NOT normalized)") + 
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        )+
        scale_x_continuous(limits = c(0, max(df_mp_univariate$index) ), 
                           breaks = seq(0, max(df_mp_univariate$index), by = 500) 
        ) +
        scale_y_continuous(limits = c(0, 1000 )) +
        # discord
        geom_vline(xintercept = df_mp_univariate$index[ input$slider ],
                   color = actual_color,
                   size = 0.5) +
        # nearest neighbor
        geom_vline(xintercept = df_mp_univariate$mp_pure_index[ input$slider ],
                   color = "red",
                   size = 0.5) +
        geom_label(data = data.frame( index = df_mp_univariate$index[input$slider],
                                      mp_pure = 800,
                                      label =  round( df_mp_univariate$mp_pure[input$slider],2)),
                   aes(label = label), color = "black", size = 5, fontface = "bold")
    }
    
    ps1 <- {
      ggplot() +
        geom_line(
          data = df_mp_univariate %>% filter(index >= input$slider,
                                             index <= input$slider +  w) ,
          aes(x = c(0:w), y = data),
          color = actual_color, size=1.5
        ) +
        geom_line(
          data = df_mp_univariate %>% filter(
            index >= df_mp_univariate$mp_index[input$slider],
            index <= df_mp_univariate$mp_index[input$slider] + w) ,
          aes(x = c(0:w), y = data),
          color = nearest_color, size=1.5
        ) +
        labs(x = NULL , y = "Power [kW]") +
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        )+ 
        scale_x_continuous(limits = c(0, w), 
                           breaks = seq(0,96,10) , 
                           expand = c(0,0)) 
    }
    
    ps2 <- {
      ggplot() +
        geom_line(
          data = df_mp_univariate %>% filter(index >= input$slider,
                                             index <= input$slider +  w) ,
          aes(x = c(0:w), y = data),
          color = actual_color, size=1.5
        ) +
        geom_line(
          data = df_mp_univariate %>% filter(
            index >= df_mp_univariate$rmp_index[input$slider],
            index <= df_mp_univariate$rmp_index[input$slider] + w) ,
          aes(x = c(0:w), y = data),
          color = nearest_color, size=1.5
        ) +
        labs(x = NULL , y = "Power [kW]") +
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        )+ 
        scale_x_continuous(limits = c(0, w), 
                           breaks = seq(0,96,10) , 
                           expand = c(0,0)) 
    }
    
    ps3 <- {
      ggplot() +
        geom_line(
          data = df_mp_univariate %>% filter(index >= input$slider,
                                             index <= input$slider +  w) ,
          aes(x = c(0:w), y = data),
          color = actual_color, size=1.5
        ) +
        geom_line(
          data = df_mp_univariate %>% filter(
            index >= df_mp_univariate$lmp_index[input$slider],
            index <= df_mp_univariate$lmp_index[input$slider] + w) ,
          aes(x = c(0:w), y = data),
          color = nearest_color, size=1.5
        ) +
        labs(x = NULL , y = "Power [kW]") +
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        ) + 
        scale_x_continuous(limits = c(0, w), 
                           breaks = seq(0,96,10) , 
                           expand = c(0,0)) 
    }
    
    ps4 <- {
      ggplot() +
        geom_line(
          data = df_mp_univariate %>% filter(index >= input$slider,
                                             index <= input$slider +  w) ,
          aes(x = c(0:w), y = data),
          color = actual_color, size=1.5
        ) +
        geom_line(
          data = df_mp_univariate %>% filter(
            index >= df_mp_univariate$mp_pure_index[input$slider],
            index <= df_mp_univariate$mp_pure_index[input$slider] + w) ,
          aes(x = c(0:w), y = data),
          color = "red", size=1.5
        ) +
        labs(x = NULL , y = "Power [kW]") +
        theme_bw() +
        theme(panel.background = element_rect(fill = "white"),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              legend.title = element_text(size = 13),
              axis.title.x = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.title.y = element_text(size = 13,margin = margin(t = 1, r = 1, b = 0, l = 0, unit = "mm")),
              axis.text.x = element_text(size = 13),
              axis.text.y = element_text(size = 13)
        ) + 
        scale_x_continuous(limits = c(0, w), 
                           breaks = seq(0,96,10) , 
                           expand = c(0,0)) 
    }
    
    ggarrange(p1, NULL, 
              p2, ps1, 
              p3, ps2, 
              p4, ps3, 
              p5, ps4,
              ncol = 2, nrow = 5, widths = c(3, 1), 
              align = "v")
    
  }, cacheKeyExpr = { input$slider } )
}

shinyApp(ui, server)