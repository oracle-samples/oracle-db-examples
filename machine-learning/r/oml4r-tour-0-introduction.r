#########################################################################
##
## Oracle Machine Learning for R Tour
## 
## Copyright (c) 2020 Oracle Corporation 
##
## The Universal Permissive License (UPL), Version 1.0
## 
## https://oss.oracle.com/licenses/upl/
##
###########################################################################
# In this Tour, we explore the different features of OML4R

rm(list=ls())

#-----------------------
# TRANSPARENCY LAYER
#-----------------------

library(ORE)
options(ore.warn.order=FALSE)
ore.connect(user="rquser",
            conn_string="ORCLPDB",
            host="localhost",
            password="rquser",
            all=TRUE)

#-- What tables are in the database schema we connected to?

ore.ls()

class(NARROW)
colnames(NARROW)
dim(NARROW)

summary(NARROW[,1:5])

#-- retrieve data from the database

narrow <- ore.pull(NARROW)
class(narrow)

str(narrow)     # data.frame

str(NARROW)     # ore.frame proxy object

NARROW@dataQry  # underlying data query for proxy object

#-- Column selection using standard R syntax

colnames(ONTIME_S)
dim(ONTIME_S)

df <- ONTIME_S[,c("YEAR","DEST","ARRDELAY")]
class(df)  # an ore.frame proxy object
dim(df)

head(df)
head(ONTIME_S[,c(1,4,23)])  # project columns using column indexes
head(ONTIME_S[,-(5:26)])    # exlcude columns using column indexes

#-- Row and column filtering

df1 <- df[df$ARRDELAY>20 | df$DEST=="BOS",1:3]
head(df1,6)

#-- Aggregation

# How many flights per destination?

aggdata <- aggregate(ONTIME_S$DEST, 
                     by = list(ONTIME_S$DEST), 
                     FUN = length)
names(aggdata) <- c("Destination","FlightCnt")
class(aggdata)
head(aggdata)


#-- Overloaded dplyr using OREdplyr on ore.frames

library(OREdplyr)   # load OREdplyr explicitly to use

select(ONTIME_S, YEAR, DEST, ARRDELAY, DEPDELAY) %>% head()   # select columns

colnames(ONTIME_S)
res <- select(ONTIME_S, -CANCELLED,-CANCELLATIONCODE, -DIVERTED) %>% head() # exclude columns
colnames(res)

dim(ONTIME_S)
filter(ONTIME_S, MONTH == 1, DAYOFMONTH == 1) %>% dim()     # filter rows
filter(ONTIME_S, DEPDELAY > 240) %>% dim()

# Group mean arrival delay by airline
tbl_avg <- ONTIME_S %>%
  group_by(UNIQUECARRIER) %>%
  summarise(avgArrDelay = round(mean(ARRDELAY, na.rm = TRUE), digits=2)) %>%
  arrange(.$avgArrDelay)
head(tbl_avg,10)
tail(tbl_avg)

#-- Join / merge data

df1 <- data.frame(x1=1:5, y1=letters[1:5])  # create two data.frames
df2 <- data.frame(x2=5:1, y2=letters[11:15])
merge (df1, df2, by.x="x1", by.y="x2")      # merge the data.frames

ore.drop(table="TEST_DF1")
ore.drop(table="TEST_DF2")
ore.create(df1, table="TEST_DF1")           # create tables from the same data.frames
ore.create(df2, table="TEST_DF2")
merge (TEST_DF1, TEST_DF2, by.x="x1", by.y="x2")  # merge the ore.frames

# using OREdplyr
res <- TEST_DF1 %>% left_join(TEST_DF2, by=c("x1"="x2"))   
res

#-- Overloaded graphics functions

# Generate boxplot of airline flight delay by day of week
delay <- ONTIME_S$ARRDELAY
dayofweek <- ONTIME_S$DAYOFWEEK
bd <- split(delay, dayofweek)
boxplot(bd, notch = TRUE, col = "red", cex = 0.5,  # statistics computed in-database
        outline = FALSE, axes = FALSE,
        main = "Airline Flight Delay by Day of Week",
        ylab = "Delay (minutes)", xlab = "Day of Week")
axis(1, at=1:7, labels=c("Monday", "Tuesday", "Wednesday", "Thursday",
                         "Friday", "Saturday", "Sunday"))
axis(2)

#---------------------------------------------
# Machine Learning 
#---------------------------------------------

#-- Classification using ore.odmNB

data(titanic3,package="PASWR")

t3 <- ore.push(titanic3)  # create ore.frame proxy object as temporary table
class(t3)   

t3$survived <- ifelse(t3$survived == 1, "Yes", "No")  # recoding

n.rows <- nrow(t3)
set.seed(seed=6218945)
random.sample <- sample(1:n.rows, ceiling(n.rows/2)) # generate sample indexes

t3.train <- t3[random.sample,]                       # train/test sampling using row indexing
t3.test  <- t3[setdiff(1:n.rows,random.sample),]

class(t3.train)  # ore.frame proxy object

priors <- c(0.4, 0.6)
names(priors) <- c("Yes", "No")

nb  <- ore.odmNB(survived ~ pclass+sex+age+fare+embarked, t3.train, class.priors=priors)

nb.res  <- predict (nb, t3.test,"survived")

head(nb.res,10)

# Compute the confusion matrix in-database
with(nb.res, table(survived,PREDICTION, dnn = c("Actual","Predicted")))

#-----------------------
# EMBEDDED R EXECUTION
#-----------------------

# Random Red Dots

RandomRedDots <- function(numDots=100){
  id <- 1:10
  print(plot( 1:numDots, rnorm(numDots), pch = 21, 
              bg = "red", cex = 2 ))
  data.frame(id=id, val=id / 100)
}

RandomRedDots(100)

dev.off()
res <- NULL
res <- ore.doEval(RandomRedDots, numDots=200)
res

ore.scriptDrop("RandomRedDots") 
ore.scriptCreate("RandomRedDots",RandomRedDots)
dev.off()
ore.doEval(FUN.NAME="RandomRedDots")


#-- Go to SQL Developer in script '~/OML4R/OML4R Vignettes.sql' and invoke function from SQL


#-- Group Apply

# Build one linear model per destination to predict arrival delay

ONTIME_S$DEST <- substr(as.character(ONTIME_S$DEST),1,3)
DAT <-   ONTIME_S[ONTIME_S$DEST %in% c("BOS","SFO","LAX","ORD","ATL","PHX","DEN"),]
dim(DAT)

modList <- ore.groupApply(X=DAT,
                          INDEX=DAT$DEST,
                          function(dat) {
                            lm(ARRDELAY ~ DISTANCE + DEPDELAY, dat)
                          })
length(modList)
summary(modList$BOS) # return model for BOS
summary(modList$SFO) # return model for SFO

# housekeeping

rm(list=ls())
dev.off()

ore.drop(table="TEST_DF1")
ore.drop(table="TEST_DF2")

ore.scriptDrop("RandomRedDots") 

ore.disconnect()

################################################
## End of Script
################################################

