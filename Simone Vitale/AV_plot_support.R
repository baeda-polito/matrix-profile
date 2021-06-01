
AV_plot_support<-function(df_data,type=c('M_A_B', 'M_A', 'C' ),df_mp_type,n_leaf,df_annotation,df_color){
  
  
  # plot_AV
  
  pp_plot<- list()
  
  pp_plot[[1]] <- ggplot()+
    geom_line(data=df_data, aes(x=X, y=Power_total))+
    xlim(0,nrow(df_data))+
    theme(axis.text.y = element_text(size = 6), axis.title.y = element_text(size = 8))
  
  
  pp_plot[[2]] <-ggplot()+
    geom_line(data=df_mp_type, aes(x=X,y=original_MP))+
    geom_point(data=df_mp_type,aes(x=X,y=original_MP[mp_discord_original==1]), color='red')+
    
    xlim(0,nrow(df_data))+
    theme(axis.text.y = element_text(size = 6), axis.title.y = element_text(size = 8))
  
  
  
  fields <- names(df_mp_type)
  
  for (ii in c(1:(length(df_annotation)-1))) {
    
    
    pp_plot[[2+ii]]<-ggplot( aes(x=X), data = df_mp_type)
    
    loop_input_mp = paste("geom_line(aes(y=mp_annotated_",n_leaf[ii],"))", sep="")
    loop_input_av = paste("geom_line(aes(y= av_",n_leaf[ii],"*max(mp_annotated_",n_leaf[ii],")), color='blue')", sep="")
    loop_input_discord<-paste("geom_point(aes(y=mp_annotated_",n_leaf[ii],"[discord_",n_leaf[ii],"==1]), color='red')", sep="")
    
    # Get the start and end points for highlighted regions
    inds <- paste("diff(c(0, df_color$color_node_",n_leaf[ii],"))",sep = "")
    inds<- eval((parse(text=inds)))
    start <- as.integer(paste(df_color$X[inds == 1]))
    end <- df_color$X[inds == -1]
    if (length(start) > length(end)) end <- c(end, tail(df_color$X, 1))
    
    # highlight region data
    rects <- data.frame(start=start, end=end, group=seq_along(start))
    rects<-rects[c(1:(nrow(rects))-1),]
    
    pp_plot[[2+ii]] <- pp_plot[[2+ii]] + eval(parse(text=loop_input_mp))+ eval(parse(text=loop_input_av))+eval(parse(text=loop_input_discord))
    
    pp_plot[[2+ii]]<- pp_plot[[2+ii]]+geom_rect(data=rects, inherit.aes=FALSE, aes(xmin=start, xmax=end, ymin=-Inf,
                                                                                   ymax=Inf, group=group), fill="orange", alpha=0.3)+
      xlim(0,nrow(df_data))
    
  }
 
  pp<-gridExtra::grid.arrange(grobs = pp_plot, ncol=1)
  
 
  ggsave(paste("./grafici/plot_AV_",type,'.png'), plot =pp,width=15,height=12)
}