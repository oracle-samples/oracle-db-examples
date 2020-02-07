################################################
##
## Oracle Machine Learning for R Demo
## 
## (c) 2020 Oracle Corporation
##
################################################

rm(list=ls())

#-----------------------
# TRANSPARENCY FRAMEWORK
#-----------------------

library(ORE)
options(ore.warn.order=FALSE)
ore.connect(user="rquser",
            conn_string="OAA1",
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

#-- Projection / column selection using standard R syntax

colnames(ONTIME_S)
dim(ONTIME_S)

df <- ONTIME_S[,c("YEAR","DEST","ARRDELAY")]
class(df)  # an ore.frame proxy object
dim(df)

head(df)
head(ONTIME_S[,c(1,4,23)])  # project columns using column indexes
head(ONTIME_S[,-(5:26)])    # exlcude columns using column indexes

#-- Selection / row filtering

df1 <- df[df$ARRDELAY>20,]
head(df1,3)

df2 <- df[df$ARRDELAY>20,c(1,3)]
head(df2,3)

df3 <- df[df$ARRDELAY>20 | df$DEST=="BOS",1:3]
head(df3,6)

#-- New in ORE 1.5.1 OREdplyr using ore.frames

library(OREdplyr)       # OREdplyr must be explicitly loaded to use

select(ONTIME_S, YEAR, DEST, ARRDELAY, DEPDELAY) %>% head()                 # select columns

colnames(ONTIME_S)
res <- select(ONTIME_S, -CANCELLED,-CANCELLATIONCODE, -DIVERTED) %>% head() # exclude columns
colnames(res)

select(ONTIME_S, DIV = DIVERTED) %>% head()                 # rename columns, but drops others
rename(ONTIME_S, DIV = DIVERTED) %>% head()                 # rename columns

dim(ONTIME_S)
filter(ONTIME_S, MONTH == 1, DAYOFMONTH == 1) %>% dim()     # filter rows
filter(ONTIME_S, DEPDELAY > 240) %>% dim()


#-- Back to standard R - Join / merge data

df1 <- data.frame(x1=1:5, y1=letters[1:5])
df2 <- data.frame(x2=5:1, y2=letters[11:15])
merge (df1, df2, by.x="x1", by.y="x2")

ore.drop(table="TEST_DF1")
ore.drop(table="TEST_DF2")
ore.create(df1, table="TEST_DF1")
ore.create(df2, table="TEST_DF2")
merge (TEST_DF1, TEST_DF2, 
       by.x="x1", by.y="x2")

# using OREdplyr
res <- TEST_DF1 %>% left_join(TEST_DF2, by=c("x1"="x2"))   
res


#-- Aggregation

# How many flights per destination?

aggdata <- aggregate(ONTIME_S$DEST, 
                     by = list(ONTIME_S$DEST), 
                     FUN = length)
names(aggdata) <- c("Destination","FlightCnt")
class(aggdata)
head(aggdata)

# What is the standard deviation of flight Arrival Delay for each carrier by destination
aggdata <- aggregate(ONTIME_S$ARRDELAY, 
                     by = list(ONTIME_S$DEST, ONTIME_S$UNIQUECARRIER), 
                     FUN = sd, na.rm=TRUE)
names(aggdata) <- c("Destination", "Airline", "sd(ArrivalDelay)")
head(aggdata,10)


#---------------------------------------------
# Predictive Analytics 
#---------------------------------------------

#-- Regression with ore.lm

mod <- ore.lm(ARRDELAY ~ DISTANCE + DEPDELAY, ONTIME_S)
summary(mod)

#-- Classification using ore.randomForest

head(iris)
IRIS.tmp <- ore.push(iris)                       # create a temporary database table

mod <- ore.randomForest(Species~., IRIS.tmp)     # build the model

tree10 <- grabTree(mod, k = 10, labelVar = TRUE) # inspect one tree
tree10

ans <- predict(mod, IRIS.tmp, type="all", supplemental.cols="Species") # use model to predict

table(ans$Species, ans$prediction)               # compute confusion matrix

#-- Classification using ore.odmNB

data(titanic3,package="PASWR")

t3 <- ore.push(titanic3)
t3$survived <- ifelse(t3$survived == 1, "Yes", "No")  # recoding

n.rows <- nrow(t3)
set.seed(seed=6218945)
random.sample <- sample(1:n.rows, ceiling(n.rows/2)) # generate sample indexes

t3.train <- t3[random.sample,]                       # train/test sampling using row indexing
t3.test  <- t3[setdiff(1:n.rows,random.sample),]

priors <- c(0.1, 0.9)
names(priors) <- c("Yes", "No")

nb  <- ore.odmNB(survived ~ pclass+sex+age+fare+embarked, t3.train, class.priors=priors)

nb.res  <- predict (nb, t3.test,"survived")

head(nb.res,10)
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

### Switch to SQL Developer to execute using SQL

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

summary(modList$BOS) ## return model for BOS

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

