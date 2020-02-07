################################################
##
## Oracle Machine Learning for R Vignettes
##
## Variable Selection - Attribute Importance
##
## (c) 2020 Oracle Corporation
##
################################################

# In this vignette, we explore a data set from Kaggle on house sales and
# identify which variables most predictive of house sale price using the in-database
# attribute importance algorithm. There are many possible techniques for variable
# selection, which is also known as 'attribute importance', feature selection',
# or 'dimensionality reduction'. 
#
# In this vignette, after exploring / preparing the data, we use the minimum description
# Length algorthm provided with OAA to rank variables according to their importance
# of predicting price. 
#
# Why do dimensionality reduction? 
#
#   1) Improve model accuracy
#   2) Remove redundant or useless variables that slow model building/scoring 
#      while adding no value, 
#   3) Improve understandability of model by using fewer variables.
#
# We will highlight a few aspects of ORE: 
#
#   * Data Access - creating database tables from R data.frames
#   * Transparency Layer - preparing and exploring data that reside in Oracle Database
#   * Predictive Analytics - using the ore.odmAI funtion, which uses the Minimum Description Length algorithm
#   * Embedded R Execution - illustrate how to produce this result at the database server from R and SQL

# Data: https://www.kaggle.com/harlfoxem/housesalesprediction

# Load the ORE library
library(ORE)

# Turn off row ordering warnings
options(ore.warn.order=FALSE)

?ore.connect  # View documentation on ore.connect

# Create an ORE Connection
ore.connect(user        ="rquser",
            conn_string ="OAA1",
            host        ="localhost",
            password    ="rquser",
            all         =TRUE)

ore.ls()        # list available tables

rm(list=ls())   # housekeeping

#################################################
# Create a database table from a CSV file in R
#################################################

setwd("~/ORE")
house <- read.csv("kc_house_data.csv")  # Kaggle data set

colnames(house)    # Verify that data loaded correctly by reviewing column names and...
head(house)        # View a few rows
str(house)         # See the data types associated with columns and adjust

#-- Visualize house sale using location data

library(ggplot2)
ggplot(house, aes(lat,long)) + geom_point(aes(colour=cut(price, breaks=8)))
ggplot(house, aes(lat,long)) + geom_point(aes(colour=cut(log(price), breaks=4)))

#-- Create database table resulting in ore.frame proxy R object

ore.drop(table="HOUSE1")           # Drop any pre-existing database table 
ore.create(house, table="HOUSE1")  # Create database table using data.frame
ore.ls(pattern="HOU")              # List tables matching pattern

colnames(HOUSE1)  # Verify names of columns in table
dim(HOUSE1)       # obtain # rows and # columns
head(HOUSE1)      # View of few records in the table to verify proper import
HOUSE1@desc       # View the data types of each variable

#-- Adjust data types with the data in the database

HOUSE1$id         <- as.character(HOUSE1$id)      # Convert id to character string
HOUSE1$date       <- substr(HOUSE1$date,1,8)      # Reduce date to minimal length required
HOUSE1$zipcode    <- as.factor(HOUSE1$zipcode)    # Convert zipcode from number to factor
HOUSE1$waterfront <- as.factor(HOUSE1$waterfront) # Convert waterfront from number to factor
HOUSE1$view       <- as.factor(HOUSE1$view)       # Convert view from number to factor
HOUSE1$condition  <- as.factor(HOUSE1$condition)  # Convert condition from number to factor
HOUSE1$grade      <- as.factor(HOUSE1$grade)      # Convert grade from number to factor

ore.drop(table="HOUSE")            # Drop any pre-existing database table HOUSE
ore.create(HOUSE1, table="HOUSE")  # Create modified table using ore.frame
ore.ls(pattern="HOU")              # List tables matching pattern

colnames(HOUSE)  # Verify names of columns in table
head(HOUSE)      # View of few records in the table to verify proper import
HOUSE@desc       # View the data types of each variable

#################################################
## Exploring Data
#################################################

#-- Use ORE Transparency Layer with overloaded summary

summary(HOUSE[,c(3:5,9)])   # use standard R syntax to focus on selected columns

#-- Generate pairs plots to visually see variable correlation

row.names(HOUSE) <- HOUSE$id                    # assign row names to enable row indexing

sample10pct <- sample(1:nrow(HOUSE),
                      round(nrow(HOUSE)*.1,0))  # Sample data so pairs plot shows patterns

pairs(HOUSE[sample10pct,3:7])          # perform a pairs plot to note any correlations visually
pairs(HOUSE[sample10pct,c(3,13:16)])   # notice yr_renovated doesn't look useful

#-- Variable yr_renovated looks suspicious, can we explore / fix?

summary(HOUSE$yr_renovated)   # this is supposed to be a year, so mean not meaningful

unique(HOUSE$yr_renovated)    # some entries use 0 for not renovated, let's fix that

HOUSE$yr_renovated <- ifelse(HOUSE$yr_renovated!=0, HOUSE$yr_renovated, NA) # replace 0 with NA for missing

summary(HOUSE$yr_renovated)   # check summary again

pairs(HOUSE[sample10pct,c(3,13:16)])   # plots involving yr_renovated now makes more sense

#-- Define new variable derived from date and explore histogram

HOUSE$age <- as.numeric(substr(HOUSE$date,1,4))-HOUSE$yr_built  # create new variable for house age at time of sale

hist(HOUSE$price, col="red")             # default histogram
hist(HOUSE$price, breaks=100, col="red") # see finer granularity with breaks argument

#-- Explore variable yr_built as it relates to price

hist(HOUSE$yr_built, col="darkgreen")        # See coarse view of when homes were built

HOUSE.split.yr_built <- with(HOUSE, split(price, yr_built)) # partition data by year built

(x <- sapply(HOUSE.split.yr_built, length))  # See how many homes built in each year

barplot(x,col="blue")               # notice drop in houses built around The Great Depression (1930s)

#-- Use more extensive and performant ore.summary function to compute other statistics

?ore.summary  # view full set of stats possible

# the stats we want apply only to numeric variables, so select these only
numericVars <- HOUSE@desc[HOUSE@desc$Sclass=="numeric" | HOUSE@desc$Sclass=="integer",
                          "name"]

statsComputed <- c("n","mean","stddev","min","p25","p50","p75","max")

statsRes <- ore.summary(HOUSE, var=numericVars, stats=statsComputed)  # compute statistics
res <- data.frame(numericVars, matrix(ore.pull(statsRes)[,-1],        # morph results into data.frame
                                      length(numericVars),length(statsComputed)))
names(res) <- c("colName",statsComputed)
res


#############################################################################
# Attribute Importance - which variables are most predictive of the PRICE?
#############################################################################

#-- Bin the target 'price'

HOUSE$priceBin <- cut(HOUSE$price, breaks=100)

#-- Compute attribute importance model

res1 <- ore.odmAI(price~., HOUSE[,-23])    # Compute as a regression problem
head(res1$importance)                      # Note that zipcode ranks high to predict price

res2 <- ore.odmAI(priceBin~., HOUSE[,-3])  # invoke in-database attribute importance algoprtihm to predict priceBin, exclude price
head(res2$importance)                      # Note that zipcode ranks high to predict priceBin

#-- Plot the importance values for visual assessment

old.par <- par(mar=c(5,8,4,2.1))  # sets bottom, left, top and right margins, respectively
barplot(res1$importance$importance, names.arg=row.names(res1$importance),
        cex.names=.75,col="red",main=paste("Attribute Importance for HOUSE dataset"),
        xlab="Importance Value",las=1,horiz=TRUE)
par(old.par)

# Alternative nice plotting using ggplot2
library(ggplot2)
# Saves the data into a data frame for plotting
aiplot <- as.data.frame(cbind(label=row.names(res1$importance[1]),
                              importance=round(res1$importance[,1],3)))
# Creates the Plot
pl <-  qplot(x=reorder(aiplot$label,as.numeric(as.character(aiplot$importance))),y=as.numeric(as.character(aiplot$importance)), fill=factor(aiplot$label),alpha = 0.9) + geom_bar(stat = "identity")

pl + ylab(label = paste0("Variable importance \nComputed from ",
                         nrow(HOUSE),
                         " rows"))+
  ggtitle(label="HOUSE PRICING ANALYSIS \n Variable Importance") +
  xlab(label = " ") +
  coord_flip() +
  scale_alpha(guide = "none") +
  theme(legend.position="none") +
  geom_text(aes(x=aiplot$label, 
                y=as.numeric(as.character(aiplot$importance)), 
                label=aiplot$importance, 
                hjust=-0.2),
            position = position_dodge(width=1)) +
  theme(plot.title = element_text(size = 14, colour = "blue"),
        axis.title=element_text(size = 12, colour = "blue"))+
  scale_y_continuous(limit = c(-0.1, 0.55))

#-- Choose variables with importance > 0.1 for data set

(vars <- row.names(res1$importance[res1$importance$importance > 0.1,])) # select vars > 0.1 importance

HOUSE.selected <- HOUSE[,c("id",vars)]  # reduce HOUSE to top variables
head(HOUSE.selected)

##################################################
## Illustrate save/load result in ORE datastore
##################################################

ore.delete(name="HOUSE_var_ranking")           # delete any previous datastore by this name

ore.save(res1, name="HOUSE_var_ranking")       # place res1 in datastore

ore.datastore()                                # list contents of full datastore

ore.datastoreSummary(name="HOUSE_var_ranking") # view objects contained in particular datastore entry

res1 <- NULL
res1
ore.load(name="HOUSE_var_ranking")             # reload object from the datastore
res1

##########################################################
# Explore selected variables using enhanced pairs plot
##########################################################

#-- Sample 10% of data to speed up plot generation, with similar trends evident

row.names(HOUSE.selected) <- HOUSE.selected$id  # enable row indexing

simpleRandomSample <- sample(1:nrow(HOUSE.selected),nrow(HOUSE.selected) * 0.05)

#-- Generate enhanced pairs plot

pairs(HOUSE.selected[simpleRandomSample,-1],    # use sampled rows, exclude 'id' column
      panel=function(x,y) {
        points(x,y,col="darkgray")
        abline(lm(y~x), lty="dashed",col="red") # compute linear model
        lines(lowess(x,y),col="green")},        # display lowess curve
      diag.panel=function(x) {
        par(new=TRUE)
        hist(x, main="",breaks=40,axes=FALSE,col="blue")} # generate histogram
)


###################################################################
# Embedded R Execution - database-side execution to return ranking
###################################################################

ore.drop(table="HOUSE2")                # Drop any pre-existing database table 
ore.create(HOUSE[,-3], table="HOUSE2")  # Create database table using ore.frame to access by table name

#-- Simplest execution 

res2 <- ore.doEval(function() {                             # define the function to execute
                      ore.sync(table="HOUSE2")              # load metadata for proxy object
                      ore.attach()                          # add env to search path
                      res1 <- ore.odmAI(priceBin~., HOUSE2) # compute importance ranking
                      res1$importance                       # return importance data.frame
                      },
                    ore.connect = TRUE)                     # requires a connection back to database

class(res2)           # returns an ore.object - serialized form of result
head(ore.pull(res2))  # Pulling result to client deserializes into data.frame


#-- Pass in tablename and dsname, save in datastore, return ore.frame

res3 <- ore.doEval(function(tablename, dsname) {        # provide arguments for table and datastore
                      ore.sync(table=tablename)
                      t1 <- ore.get(tablename)          # dynamically get ore.frame proxy by name
                      res1 <- ore.odmAI(priceBin~., t1)
                      ore.save(res1, name=dsname, overwrite=TRUE) # store result in datastore
                      res <- res1$importance            # create complete data.frame from importance
                      data.frame(var = rownames(res), res$importance, res$rank) # explicit col for row names
                      },
                   ore.connect = TRUE, tablename="HOUSE2", dsname="HOUSE_var_ranking2", # pass args
                   FUN.VALUE = data.frame(var="a", importance=1,rank=1))  # specify result format for ore.frame

class(res3)  # ore.frame
head(res3)   # deferred execution, computed when accessed

ore.datastore()                                 # list contents of full datastore
ore.datastoreSummary(name="HOUSE_var_ranking2") # view objects contained in particular datastore entry

#-- Save function in ORE R Script Repository

# same function as above
myFunction <- function(tablename, dsname) {
  ore.sync(table=tablename)
  t1   <- ore.get(tablename)
  res1 <- ore.odmAI(priceBin~., t1)
  ore.save(res1, name=dsname, overwrite=TRUE)
  res <- res1$importance
  data.frame(var = rownames(res), res$importance, res$rank)
}

# Save in R Script reporistory
ore.scriptCreate("HOUSE_var_ranking", myFunction, overwrite=TRUE) 

# Invoke by name instead of with explicit function
res4 <- ore.doEval(FUN.NAME="HOUSE_var_ranking",
                   ore.connect = TRUE, tablename="HOUSE2", dsname="HOUSE_var_ranking2",
                   FUN.VALUE = data.frame(var="a", importance=1,rank=1))

class(res4)  # ore.frame
head(res4)   # deferred execution, computed when accessed

#-- STOP: Go to SQL Developer and invoke functions from SQL

# select * 
# from table(rqEval(cursor(select 1 "ore.connect",'HOUSE2' "tablename", 'HOUSE_var_ranking2' "dsname" from dual),
#                   'select ''aaaaaaaaaaaaaaaaaaaaa'' var, 1 importance, 1 rank from dual',
#                   'HOUSE_var_ranking'));

# clean up -- DO NOT RUN until you completed the SQL Developer execution

rm(list = ls())
ore.delete(name="HOUSE_var_ranking")
ore.delete(name="HOUSE_var_ranking2")
ore.scriptDrop("HOUSE_var_ranking")
ore.drop(table="HOUSE")
ore.drop(table="HOUSE1")
ore.drop(table="HOUSE2")
ore.disconnect()

################################################
## End of Script
################################################

