##CART ANALYSYS
library(rpart)                 #CART
library(partykit)
library(lubridate)             # makes it easier to work with dates and times
library(dplyr)                 # manipulate data, mutate()
library(magrittr)              #%>% pipe operator
library(ggplot2)               # to plot
library(ggparty)               #to plot ggparty variable
library(ggpubr)
library(plotly)
library(caret)

# create a data frame, load data_tot.csv
df <- read.csv("data/data_tot.csv")
# 
df <- df %>%
  mutate(Timestamp=as.POSIXct(Timestamp, tz = "GMT", "%Y-%m-%dT%H:%M:%OS")) %>%
  mutate(Date=as.Date(Timestamp),
         Year=year(Timestamp),
         Month=month(Timestamp),
         Month_day=day(Timestamp),
         Week_day=wday(Timestamp),
         Hour=hour(Timestamp),
         Minute=minute(Timestamp),
         Time=as.factor(format(Timestamp, '%H:%M')))
         
colnames(df)[which(names(df) =='Total_Power')]<-"Power_total"

## BUILD CART MODEL

# Fit the model on the training set

pruning <- train(
  Power_total ~ Time+ Holiday+ as.factor(Week_day)+ as.factor(Month), data = df, method = "rpart",
  trControl = trainControl("cv", number = 5),
  tuneLength = 5
)
# Plot model accuracy vs different values of
# cp (complexity parameter)
plot(pruning)


rt <-rpart(data=df, Power_total ~ Time+ Holiday+ as.factor(Week_day)+ as.factor(Month), control = rpart.control(maxdepth=4))
# rt <-as.party(rt)

dev.new()
png(file="./grafici/p_cart.png",height = 1000,width = 1500)

# plot_rt<-ggparty(rt) +
#   geom_edge() +
#   geom_edge_label() +
#   geom_node_label(aes(label = splitvar), color='red', ids = "inner") +
#   geom_node_label(aes(label = info), ids = "terminal")
#   
#   
plot(as.party(rt,main = "REGRESSION TREE", gp = gpar(fontsize = 2),inner_panel=node_inner,ip_args=list( abbreviate = TRUE,  id = FALSE)))

dev.off()


save(rt,file = './data/rt.Rdata')

# grow tree 
rt_1 <- rpart( Power_total ~ Time +Holiday +as.factor(Week_day)+ as.factor(Month), 
             method="anova", data=df,control = rpart.control(maxdepth=4, cp=pruning$bestTune))

printcp(rt_1) # display the results 
dev.new()
plotcp(rt_1) # visualize cross-validation results 
summary(rt_1) # detailed summary of splits

# create additional plots 
par(mfrow=c(1,2)) # two plots on one page 
dev.new()
rsq.rpart(rt_1) # visualize cross-validation results   





