################################################
##
## Using R for Big Data Advanced Analytics
##           and Machine Learning
##
## Hands-On Lab
##
## (c) 2020 Oracle Corporation
##
################################################

# Load the Oracle R Enterprise library
library(ORE)

# Turn off row ordering warnings, which happens since
# the Oracle Database stores the data using indexes
options(ore.warn.order=FALSE)

# Create an ORE Connection to the Oracle Database
?ore.connect  # View documentation on ore.connect

ore.connect("rquser", 
            conn_string="OAA1", 
            host= "localhost", 
            password="rquser", 
            all=TRUE)

# Housekeeping: clean all objects from memory
# and make sure tto delete the table AUTO if it exists
rm(list = ls())
if (ore.exists("AUTO")) ore.drop(table="AUTO")

#################################################
# Loading data from a flat file
#################################################

?read.csv             # Notice other functions, like read.table
setwd("~/ORE")        # set the working directory where file is located

# load data from CSV file to R's local memory
dat <- read.csv(file="CUST_INSUR_LTV.csv", header=TRUE)

# Create a temporary Oracle Database table with ore.frame by
# pushing the data
DAT <- ore.push(dat)

# NOTE: if the connection is terminated for any reason, 
# the temporary table is dropped, but the local DAT 
# object would still remain (but will not work without the
# connectivity.

class(DAT)            # see that it is an ore.frame
str(DAT)              # view the structure of the object
DAT@dataQry           # corresponding SQL query for the data
DAT@sqlTable          # database temporary table name

# NOTE: To test the query, in SQLPlus or SQL Developer
# you can try to run "select count(*) from ORE$x__y", 
# where x and y are given in @sqlTable

ore.ls()              # list available table. notice DAT is not listed

# Drop the table named "CUST_LTV" if it exists
if (ore.exists("CUST_LTV")) ore.drop(table="CUST_LTV")

# Create a persistent database table with the proxy object
ore.create(dat,table="CUST_LTV") 

ore.ls(pattern="CUST")           # Notice that CUST_LTV is now listed
CUST_LTV@dataQry                 # See the query supporting the proxy
CUST_LTV@sqlTable                # See that table name is just CUST_LTV

#################################################
# Accessing Database Tables
#################################################

# Disconnect from rquser and reconnect as rquser2
ore.disconnect()
ore.connect("rquser2", conn_string="OAA1", host= "localhost", password="rquser2", all=TRUE)
ore.ls()

# Create tables in RQUSER2 schema
library(ISLR)      # source of data sets

ore.drop(table="COLLEGE")
ore.create(College, table="COLLEGE")

if (ore.exists("AUTO")) ore.drop(table="AUTO")
Auto2 <- Auto
Auto2$cylinders <- as.factor(Auto2$cylinders)
Auto2$year <- as.factor(Auto2$year)
Auto2$origin <- as.factor(Auto2$origin)
Auto2$name <- as.character(Auto2$name)
str(Auto2)
ore.create(Auto2, table="AUTO")
ore.ls()

# Grant access to these tables to RQUSER - use SQL via ore.exec
ore.exec("grant select on college to rquser")
ore.exec("grant select on auto to rquser")

# Change schema to RQUSER 
ore.disconnect()
ore.connect("rquser", conn_string="OAA1", host= "localhost", password="rquser", all=TRUE)

?ore.sync                 # view documentation on these functions
?ore.attach

ore.ls()                  # list available tables
ore.ls(pattern="AUTO")    # see that AUTO is not present

ore.sync(table=c("COLLEGE","AUTO"), schema="RQUSER2")  # load objects from other schema
ore.attach(schema="RQUSER2")                           # place schema in search path
ore.ls()                  # new tables don't show up in general listing
ore.ls(schema="RQUSER2")  # specify schema to see these tables

# With the ore.frames found in search path, see # rows and columns
dim(COLLEGE)
dim(AUTO)

# Create an ore.frame from a query
ore.sync(query = c("CUST_LTV_HIGH" = "select * from CUST_LTV where LTV_BIN = 'HIGH' OR LTV_BIN = 'VERY HIGH' "))
ore.ls(pattern='CUST_LTV_HIGH')
summary(CUST_LTV_HIGH$LTV_BIN)

####################################################
# Accessing Shared Datastores
####################################################

# Store and share R objects through Oracle Database

ore.datastore()                 # show default contents of Datastore

# Create your own local copies of these data.frames
my_iris <- iris
my_mtcars <- mtcars
my_arrests <- USArrests
ore.save(my_iris, name="ds_1")                    # save R's iris data set in a data store
ore.save(my_mtcars, name="ds_2", grantable=TRUE)  # create grantable datastore on mtcars
ore.save(my_arrests, name="ds_3", grantable=TRUE) # create grantable datastore on USArrests
ore.datastore(type="all")[,1:3]                   # show all datastores

# Grant read to all users
ore.grant(name="ds_2", type="datastore", user=NULL)

# Show all datastores
ore.datastore(type="all")[,1:3]  # no change

# show grantable datstores
ore.datastore(type="grantable")[, 1:2]  # need to select type

# show datastores where read granted
ore.datastore(type="grant")

# grant read to RQUSER2
ore.grant(name="ds_3", type="datastore", user="RQUSER2")

# show datastores where read granted
ore.datastore(type="grant")

# Change schema to RQUSER2
ore.disconnect()
ore.connect("rquser2", conn_string="OAA1", host= "localhost", password="rquser2", all=TRUE)

# Show all datastores in rquser2

ore.datastore(type="all")[,1:3]

# Load shared datastores
ore.load("ds_2",owner="RQUSER")
ore.load("ds_3",owner="RQUSER")

# Change schema back to RQUSER
ore.disconnect()
ore.connect("rquser", conn_string="OAA1", host= "localhost", password="rquser", all=TRUE)

# Revoke grants
ore.revoke(name="ds_2", type="datastore", user=NULL)
ore.revoke(name="ds_3", type="datastore", user="RQUSER2")
ore.datastore(type="grant")

# Change schema to RQUSER2
ore.disconnect()
ore.connect("rquser2", conn_string="OAA1", host= "localhost", password="rquser2", all=TRUE)

# Show all datastores
ore.datastore(type="all")[,1:3]         

# Change schema back to RQUSER
ore.disconnect()
ore.connect("rquser", conn_string="OAA1", host= "localhost", password="rquser", all=TRUE)

# clean up
ore.delete(name="ds_1")
ore.delete(name="ds_2")
ore.delete(name="ds_3")

ore.datastore(type="all")[,1:3]

#################################################
## Exploring Data
#################################################

# Statistics on CUST_LTV
# Create an ore.frame from a query
ore.sync(query = c("CUST_LTV_HIGH" = "select * from CUST_LTV where LTV_BIN = 'HIGH' OR LTV_BIN = 'VERY HIGH' "))
ore.ls(pattern='CUST')

# The Overloaded summary function is computed in-database
summary(CUST_LTV[,c(1:5,30,31)])

# Notice that LTV_BIN now has only two values
summary(CUST_LTV_HIGH[,c(1:5,30,31)])

# Statistics for single variable AGE
summary(CUST_LTV$AGE)

# Use the scalable ore.summary to compute a range of summary statistics
?ore.summary

ore.summary(CUST_LTV, class="SEX", var=c("AGE","SALARY","LTV"))

ore.summary(CUST_LTV, class=c("SEX","BUY_INSURANCE"),
            var=c("AGE","SALARY","LTV"))

ore.summary(CUST_LTV, c("AGE", "SALARY"), "mean", class="SEX",
            maxid=c(MORTGAGE_AMOUNT="CHECKING_AMOUNT", 
                    N_TRANS_ATM="N_TRANS_KIOSK"))

#######################################################################
# Visualization on CUST_LTV using overloaded R functions on ore.frames
#######################################################################
# The function hist is also overloaded, where the result is computed by
# the Oracle Database and the chart is built in R using the results 
# automatically
hist(CUST_LTV$AGE, col="red")

pairs(CUST_LTV[,c("AGE", "SALARY", "CHECKING_AMOUNT", "CREDIT_BALANCE")],col="darkblue")

with(CUST_LTV,pairs(cbind(AGE, SALARY, LTV),
                    panel=function(x,y) {
                      points(x,y,col="darkgray")
                      abline(lm(y~x), lty="dashed",col="red") # compute linear model
                      lines(lowess(x,y),col="green")},        # display lowess curve
                    diag.panel=function(x) {
                      par(new=TRUE)
                      hist(x, main="",axes=FALSE,col="blue")} # generate histogram
))


#################################################
# Statistics on AUTO
#################################################

# Access AUTO table from RQUSER2 schema
ore.sync(table=c("AUTO"), schema="RQUSER2")
ore.attach(schema="RQUSER2")

# Check a few rows of the Oracle Database table, and
# view statistics
head(AUTO)
summary(AUTO)

#################################################
# Visualization on AUTO
#################################################
# Which attributes have obvious correlations?
pairs(AUTO)

# Focus in on these variables
pairs(~mpg + displacement+horsepower+weight+acceleration , AUTO)

row.names(AUTO) <- AUTO$name  # use ORE row indexing to access rows by index later

with(AUTO, plot(horsepower ,mpg))

# Click pts on the graph, click ESC when finished

indxs <- with(AUTO, identify (horsepower ,mpg ,name))

AUTO[indxs,"name"]  # use indexes to lookup names

with(AUTO,pairs(cbind(mpg,displacement,
                      horsepower,weight,acceleration),
                panel=function(x,y) {
                  points(x,y,col="darkgray")
                  abline(lm(y~x), lty="dashed",col="red")
                  lines(lowess(x,y),col="green")},
                diag.panel=function(x) {
                  par(new=TRUE)
                  hist(x, main="",axes=FALSE,col="blue")}
))

# The boxplot function is also overloaded
boxplot(mpg~cylinders,data=AUTO, main="Car Mileage Data",
        xlab="Number of Cylinders",
        ylab="Miles Per Gallon",col="green")

coplot(mpg ~ horsepower | weight, data = AUTO)

# The following 2 Charts might be too large if you are runnng these on
# a smaller resolution
coplot(mpg ~ horsepower | weight * acceleration, data = AUTO,
       col = "red", bg = "pink", pch = 21,
       bar.bg = c(fac = "light blue"))

coplot(mpg ~ horsepower | weight * acceleration, data = AUTO,
       col = "darkgreen", pch = 21,
       panel=function(x,y,...) {
         panel.smooth(x,y, span=.8,iter=5,...)
         abline(lm(y~x),col="blue")
      })


#################################################
## Preparing Data
#################################################

# Recode transformation - in-database
# View the data values for HAS_CHILDREN
head(CUST_LTV$HAS_CHILDREN)
table(CUST_LTV$HAS_CHILDREN)

ore.crosstab(~HAS_CHILDREN, data=CUST_LTV)        # Alternate way to check counts

ore.crosstab(HAS_CHILDREN ~ SEX + BUY_INSURANCE,  # 2-way tables example
             data=CUST_LTV)

# create a format function to convert 0/1 to No/Yes using ifelse
hasChildren_fmt <- function (x) {
  ifelse(x=='0', 'No',
  ifelse(x=='1', 'Yes','unknown'))
}

# recode the values by invoking the function and reassigning to the same variable
CUST_LTV$HAS_CHILDREN <- hasChildren_fmt(CUST_LTV$HAS_CHILDREN)

# view recoded values
head(CUST_LTV$HAS_CHILDREN)
table(CUST_LTV$HAS_CHILDREN)

# recode using transform() for origin with name instead of numeric id
head(AUTO$origin)
table(AUTO$origin)
AUTO <- transform(AUTO,
                  origin2 = ifelse(origin==1,"American",
                            ifelse(origin==2,"European",
                            ifelse(origin==3,"Japanese","unknown"))))
head(AUTO$origin2)
table(AUTO$origin2)

# Recode using ore.recode()
AUTO$origin3 <-  ore.recode(AUTO$origin,
                            c("1", "2", "3"),
                            c("American", "European", "Japanese"),
                            "unknown")
table(AUTO$origin3)

AUTO$origin4 <-  ore.recode(AUTO$origin,
                            c("1", "2", "3"),
                            c("American", "Foreign", "Foreign"),
                            "unknown")
table(AUTO$origin4)

# Bin transformation - in-database
# Use manual specification of bin boundaries using ifelse
CUST_LTV$AGE_BIN <- with(CUST_LTV, ifelse(AGE < 20, "0-20",
                                   ifelse(AGE < 30, "20-30",
                                   ifelse(AGE < 50, "30-50",
                                   ifelse(AGE >=50,"50+","unknown")))))
class(CUST_LTV$AGE_BIN)
table(CUST_LTV$AGE_BIN)

# Using AGE directly,  this graph is not very informative
boxplot(SALARY ~ AGE + SEX, data=CUST_LTV[CUST_LTV$AGE < 40,])

# A more informative graph with binned age
boxplot(SALARY ~ AGE_BIN + SEX, data=CUST_LTV[CUST_LTV$AGE < 40,],col="green")

# Plot using a manual binning approach
class(CUST_LTV$AGE_BIN)
barplot(table(CUST_LTV$AGE_BIN),col="brown",main="Manual Binning with Function")

# Convert to ore.factor - same results
CUST_LTV$AGE_BIN2 <- as.ore.factor(CUST_LTV$AGE_BIN)
levels(CUST_LTV$AGE_BIN2)
class(CUST_LTV$AGE_BIN2)
barplot(table(CUST_LTV$AGE_BIN2),col="lightblue",main="Variable converted to Factor")

# Bin using cut() for 4 bins simply specifying cut points - same results
CUST_LTV$AGE_BIN3 <- cut(CUST_LTV$AGE,c(0,20,30,50,100),right=FALSE)
barplot(table(CUST_LTV$AGE_BIN3),col="lightgreen",main="Bin with 'cut' specifying boundaries")

# Binning using 'cut' function for 4 bins -- equidistant bins -- very different result
CUST_LTV$AGE_BIN2 <- cut(CUST_LTV$AGE,4)
barplot(table(CUST_LTV$AGE_BIN2),col="pink",main="Bin with 'cut' specifying # bins")

# Normalize transformation - in-database
# z-score normalization
zscore <- function(x) {
  (x-mean(x,na.rm=TRUE))/sd(x,na.rm=TRUE)
}

AUTO$mpg_zscore   <- zscore(AUTO$mpg)
par(mfrow = c(1, 2))
boxplot(AUTO$mpg,main="Original mpg",ylab="mpg",col="red")

# Notice the distribution is the same, but scale is different
boxplot(AUTO$mpg_zscore, main="Z-Score mpg",ylab="zscore",col="blue")
par(mfrow = c(1, 1))

# Normalize using min-max between 0 and 1
minMaxNormalize <- function(x) {
  mn <- min(x)
  mx <- max(x)
  y <- (x-mn)/(mx-mn)
  y
}

# Invoke function to normalize mpg
AUTO$mpg_minMaxNorm   <- minMaxNormalize(AUTO$mpg)
par(mfrow = c(1, 3))
boxplot(AUTO$mpg,main="Original mpg",ylab="mpg",col="red")
boxplot(AUTO$mpg_zscore, main="Z-Score mpg",ylab="zscore",col="blue")

# Notice the distribution is the same, but again, scale is different, between 0 & 1
boxplot(AUTO$mpg_minMaxNorm, main="Min-Max mpg",ylab="Normalized 0-1",col="blue")
par(mfrow = c(1, 1))

# Outlier Treatment transformation - in-database
# View distribution of displacement
summary(AUTO$displacement)

# Remove outliers - define function to set outliers to NA
removeOutliers <- function(x, multiplier = 1.5, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
  H <- multiplier * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
}

# Invoke function to remove outliers
AUTO$displacementRMO <- removeOutliers(AUTO$displacement,1)

# View new distribution and number of missing values
summary(AUTO$displacementRMO)

# Replace outliers with max and min values
# View distribution of displacement
summary(AUTO$displacement)

# Define function to set outliers to 2 standard deviations from mean
capOutliers <- function(x, num.sd = 2, na.rm = TRUE, ...) {
  maxLimit<- mean(x,na.rm=na.rm)+ num.sd*sd(x,na.rm=na.rm)
  minLimit <- mean(x,na.rm=na.rm)- num.sd*sd(x,na.rm=na.rm)
  y <- x
  y[x < minLimit] <- minLimit
  y[x > maxLimit] <- maxLimit
  y
}

# Replace outliers
AUTO$displacementRPO <- capOutliers(AUTO$displacement)

# Remove outliers - define function to set outliers to NA
removeOutliers <- function(x, multiplier = 1.5, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
  H <- multiplier * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
}

# Remove outliers
AUTO$displacementRMO <- removeOutliers(AUTO$displacement,1)

# Compare distributions and number of missing values
summary(AUTO[,c("displacement", "displacementRMO", "displacementRPO")])

par(mfrow = c(1, 3))
boxplot(AUTO$displacement,main="Original displacement",ylab="displacement",col="red",ylim=c(0,500))
boxplot(AUTO$displacementRMO, main="Remove Outliers",ylab="displacement",col="blue",ylim=c(0,500))
boxplot(AUTO$displacementRPO, main="Replace Outliers",ylab="displacement",col="green",ylim=c(0,500))
par(mfrow = c(1, 1))

# Missing Value Treatment transformation - in-database
# View distribution of displacement with removed outliers
summary(AUTO$displacementRMO)

# Define function to replace missing values with specific value, mean by default
missingValueTeatment <- function (x, value=mean(x,na.rm=TRUE)) {
  y <- ifelse(is.na(x), value,x)
  y
}

# Treat missing values
AUTO$displacementMVT <- missingValueTeatment(AUTO$displacementRMO)

# View new distribution - notice it's the same, but with no NA values
summary(AUTO$displacementMVT)

# Treat missing values using median instead of mean
AUTO$displacementMVT2 <- missingValueTeatment(AUTO$displacementRMO,
                                              value=median(AUTO$displacementRMO,na.rm=TRUE))

# View new distribution - notice it's slightly different and with no NA values
summary(AUTO$displacementMVT2)

# Compare replacing outliers result with missing value treatments
par(mfrow = c(1, 3))
boxplot(AUTO$displacementRPO, main="Replace Outliers",ylab="displacement",col="red",ylim=c(0,500))
boxplot(AUTO$displacementMVT, main="Missing Value Treatment - mean",ylab="displacement",col="blue",ylim=c(0,500))
boxplot(AUTO$displacementMVT2, main="Missing Value Treatment - median",ylab="displacement",col="green",ylim=c(0,500))
par(mfrow = c(1, 1))


#################################################
## Sampling - in-database
#################################################
# Simple Random Sampling
# Check the dimensions of the Table
dim(CUST_LTV)

# Make example repeatable
set.seed(1)
N <- nrow(CUST_LTV)
sampleSize <- 2000

# Sample 2,000 rows from the Table
# Expect an ERROR
simpleRandomSample2000 <- CUST_LTV[sample(N, sampleSize), ,drop=FALSE]

# It will give an ERROR because the Oracle Database needs to get
# a column with unique values assigned as row.names if we want to 
# extract rows by number (tHe Oracle Database will use an Index)
# Assign a row.names column
row.names(CUST_LTV) <- CUST_LTV$CUST_ID

# Try again
simpleRandomSample2000 <- CUST_LTV[sample(N, sampleSize), ,drop=FALSE] # Succeeds

# The sample still remains in-database
dim(simpleRandomSample2000)
class(simpleRandomSample2000)
head(simpleRandomSample2000)

# Take a few samples and compare distributions
simpleRandomSample1000 <- CUST_LTV[sample(N, 1000), ,drop=FALSE]
simpleRandomSample500  <- CUST_LTV[sample(N, 500), ,drop=FALSE]

summary(CUST_LTV$AGE)
summary(simpleRandomSample2000$AGE)
summary(simpleRandomSample1000$AGE)
summary(simpleRandomSample500$AGE)

# Easier to view graphically - notice only minor variation
par(mfrow = c(1, 4))
boxplot(CUST_LTV$AGE, main=paste("No Sampling -",N),ylab="AGE",col="red",ylim=c(0,100))
boxplot(simpleRandomSample2000$AGE, main="Sample 2000",ylab="AGE",col="blue",ylim=c(0,100))
boxplot(simpleRandomSample1000$AGE, main="Sample 1000",ylab="AGE",col="green",ylim=c(0,100))
boxplot(simpleRandomSample500$AGE, main="Sample 500",ylab="AGE",col="green",ylim=c(0,100))
par(mfrow = c(1, 1))

# Split Sampling - produce train and test data set
N <- nrow(CUST_LTV)
trainPct <- 60
ind <- sample(1:N,trainPct*N/100)           # get indices for samples
group <- as.integer(1:N %in% ind)           # generate logical vector for selection

row.names(CUST_LTV) <- CUST_LTV$CUST_ID
CUST_LTV.train <- CUST_LTV[group==FALSE,]   # select the train records
dim(CUST_LTV.train)
class(CUST_LTV.train)

CUST_LTV.test <- CUST_LTV[group==TRUE,]     # select the test records
dim(CUST_LTV.test)

# Compare total number of rows in source, with sum of train and test
nrow(CUST_LTV)
nrow(CUST_LTV.train) + nrow(CUST_LTV.test)


#################################################
## Model Building and Scoring
#################################################

# Reload AUTO to remove previous changes
rm(AUTO)
ore.sync(table="AUTO",schema="RQUSER2")

# Attribute Importance - which variables are most predictive of the target?
res <- ore.odmAI(mpg ~ ., AUTO)
res

res$importance  # No surprise that mpg variants predict mpg very well!

# Plot the importance values for visual assessment
# The following sets the bottom, left, top and right margins respectively
old.par <- par(mar=c(5,8,4,2.1))

barplot(res$importance$importance, names.arg=row.names(res$importance),
        cex.names=.75,col="red",main="Attribute Importance for AUTO dataset",
        xlab="Importance Value",las=1,horiz=TRUE)
par(old.par)

# Choose variables with importance > 0.1 for data set in AUTO.ai

vars <- row.names(res$importance[res$importance$importance > 0.1,])
AUTO.ai <- AUTO[,c("mpg","name",vars)]

# Regression using Support Vector Machine (SVM)
mpg.svm.mod <- ore.odmSVM(mpg ~ .-name, AUTO.ai, "regression", kernel="linear")
summary(mpg.svm.mod)

res <- predict(mpg.svm.mod, AUTO,supplemental.cols=c("name","mpg"))
class(res)
head(res)

# Highlight vehicles with greatest difference from predicted values
res$diff <- res$PREDICTION - res$mpg
res$absdiff <- abs(res$diff)
head(res)
row.names(res) <- res$name
res$name <- NULL
res2 <- ore.sort(res, by="absdiff", reverse=TRUE)

head(res2,10)  # biggest differences are where vehicle does better than predicted


# Classification using SVM
ltv_bin.svm.mod <- ore.odmSVM(LTV_BIN ~ .-LTV, CUST_LTV.train[5:31], "classification")

ltv_bin.pred <- predict(ltv_bin.svm.mod, CUST_LTV.test,
                        supplemental.cols=c("CUST_ID","LTV_BIN"))

# View predictions - notice that all probabilities are provided along with prediction
head(ltv_bin.pred)

# Generate confusion matrix
(tab1 <- with(ltv_bin.pred, table(LTV_BIN, PREDICTION, dnn = c("Actual","Predicted"))))

# Classification using Decision Tree
ltv_bin.dt.mod <- ore.odmDT(LTV_BIN ~ .-LTV, CUST_LTV.train[5:31])

ltv_bin.pred <- predict(ltv_bin.dt.mod, CUST_LTV.test,
                        supplemental.cols=c("CUST_ID","LTV_BIN"))

# View predictions - notice that all probabilities are provided along with prediction
head(ltv_bin.pred)

# Generate confusion matrix
(tab1 <- with(ltv_bin.pred, table(LTV_BIN, PREDICTION, dnn = c("Actual","Predicted"))))

# Classification using Random Forest

IRIS <- ore.push(iris)
mod <- ore.randomForest(Species~., IRIS)
tree10 <- grabTree(mod, k = 10, labelVar = TRUE)
ans <- predict(mod, IRIS, type="all", supplemental.cols="Species")
table(ans$Species, ans$prediction)  # learns perfectly

mod <- ore.randomForest(cylinders~.-name, AUTO)
tree10 <- grabTree(mod, k = 10, labelVar = TRUE)
ans <- predict(mod, AUTO, type="all", supplemental.cols="cylinders")
table(ans$cylinders, ans$prediction)  # learn perfectly

################################################################
## Build multiple models in parallel with Embedded R Execution
################################################################

# Regression to predict arrival delay for specific airlines
# use a subset of data for demonstration
DAT <- ONTIME_S[c(6,11,17,18,21)]
DAT <- subset(DAT, UNIQUECARRIER %in% c("AA","DL","NW","UA"))
head(DAT)

# Build one lm model and return coefficients for each airline, save model
res <- ore.groupApply(DAT,
                      INDEX = DAT$UNIQUECARRIER,
                      function(df) {
                        if(nrow(df) == 0)
                          NULL
                        else
                          coef(lm(ARRDELAY ~ DEPDELAY+DISTANCE,data=df))
                      },
                      parallel = 4)
res


# Use 2 columns for partitioning data, build models per day per airline
res <- ore.groupApply(DAT,
                      INDEX = DAT[,c(1,2)],
                      function(df) {
                        if(nrow(df) == 0)
                          NULL
                        else {
                          cc <- coef(lm(ARRDELAY ~ DEPDELAY+log(DISTANCE),data=df))
                          df <- data.frame(Day=df[1,1],
                                           Airline=df[1,2],
                                           Intercept=cc[1],
                                           DEPDELAY=cc[2],
                                           DISTANCE=cc[3])
                          row.names(df) <- NULL
                          df
                        }
                      },
                      parallel = 4)
res

length(res)  # number of models produced

# Reshape data to facilitate plotting using ggplot
# Load the reshape2 and ggplot2 libraries
library(reshape2)
library(ggplot2)

# Need to pull data to client since melt is not overloaded
res2 <- melt(ore.pull(res), id=c("Day","Airline"))

# Notice differences in intercept for certain airlines on certain days
# Notice distance has inverse relationship to arrival delay -- making up time
ggplot(data=res2, aes(x=variable, y=value, fill=Airline)) +
  geom_bar(stat="identity", position=position_dodge()) +
  facet_wrap(~Day, ncol=1, scales="free")

#################################################
## Viewing ODM models in ODMr
#################################################

# Obtain the identifier of the specific models to inspect
str(mpg.svm.mod)
mpg.svm.mod$name
ltv_bin.svm.mod$name
ltv_bin.dt.mod$name

# Using SQL Developer, connect to RQUSER schema via ODMr
# (the Oracle Data Miner UI)
# Create a "Model" node and select the models of interest
# multiple Model nodes may be required

#################################################
# Model Scoring using R models
#################################################

# R Models using Embedded R Execution with CRAN package e1071
library(e1071)
library(ISLR)

rm(AUTO)                # remove AUTO ore.frame from client memory
ore.sync(table="AUTO", schema="RQUSER2")  # reload AUTO ore.frame from RQUSER2 schema
row.names(AUTO) <- AUTO$name
head(AUTO)

# Build a Naive Bayes model to predict number of cylinders
cyl.mod.nb <- naiveBayes(cylinders ~ ., data = Auto2[,1:8])

# Use model to predict a few rows
predict(cyl.mod.nb,Auto2[1:5,1:8],type="class")

# Check the structure of the input data
scoreNBmodel_A <- function(dat) {
  capture.output(str(dat))
}

res <- ore.rowApply(
  AUTO[,1:8],
  scoreNBmodel_A,
  rows=10)

res[[1]]

# Compare structure with Auto2 from which model was built
# notice factor variables in Auto2 and the character vectors in AUTO
str(Auto2)

# Define function to convert variables to factors
# Metadata about factors is not available in a database table
scoreNBmodel <- function(dat, mod) {
  library(e1071)
  dat$cylinders <- factor(dat$cylinders)
  dat$year      <- factor(dat$year)
  dat$origin    <- factor(dat$origin)
  dat$PRED      <- predict(mod, newdata = dat,type="class")
  dat
}


# Invoke using ore.rowApply using batches of 10 rows, with 2 R engines in parallel
res <- ore.rowApply(
  AUTO[,1:8],
  scoreNBmodel,
  mod = cyl.mod.nb,
  rows=10, parallel=2)

class(res)            # ore.list
res[[1]]              # view result
str(res[[1]])         # view structure of result, notice factors

# Change output to return single table result as ore.frame, instead of ore.list
res2 <- ore.rowApply(
  AUTO[,1:8],
  scoreNBmodel,
  mod = cyl.mod.nb,
  FUN.VALUE = res[[1]],  # provide structure of previous result
  rows=10, parallel=2)

class(res2)           # ore.frame
head(res2)

table(res2$cylinder, res2$PRED)


# Scoring with R Models using ore.predict
library(rpart)
set.seed(123)

# Build classification model using rpart to predict number of cylinders
cyl.rpart.mod <- rpart(cylinders ~ .-name, data = Auto)

# Reinitialize AUTO to database contents
rm(AUTO)                # remove AUTO ore.frame from client memory
ore.sync(table="AUTO", schema="RQUSER2")  # reload AUTO ore.frame from RQUSER2 schema
row.names(AUTO) <- AUTO$name
head(AUTO)

# Use ore.predict to score in-database using AUTO ore.frame
AUTO.res <- ore.frame(AUTO[,c("name","cylinders")],
                      ore.predict(cyl.rpart.mod, AUTO))

names(AUTO.res) <- c("name","cylinders","pred.cylinders")

# View sample of predictions
AUTO.res[sample(1:nrow(AUTO.res),10),]

# Round to get whole number and view again
AUTO.res$pred.cylinders <- round(AUTO.res$pred.cylinders,1)
AUTO.res[sample(1:nrow(AUTO.res),10),]

table(AUTO.res$cylinders, AUTO.res$pred.cylinders)


#################################################
## Solution Deployment
#################################################

# Returning structured data as Tables for use in, e.g., OBIEE
# Store script in R Script Repository
ore.scriptList()
ore.scriptCreate("scoreNBmodel",scoreNBmodel, overwrite=TRUE)

# Verify function works from R with ore.rowApply
res3 <- ore.rowApply(
  AUTO[,1:8],
  FUN.NAME="scoreNBmodel",
  mod = cyl.mod.nb,
  FUN.VALUE = res[[1]],
  rows=10)
head(res3)

# Since can't pass a model in SQL, need to store in datastore
ore.delete("CYL_NB_MODEL_1")    # clean up if datastore exists from previous execution
ore.save(cyl.mod.nb,name="CYL_NB_MODEL_1")
ore.datastore()

# Revise function to load from datastore name
scoreNBmodel2 <- function(dat, dsname) {
  library(e1071)
  dat$cylinders <- factor(dat$cylinders)
  dat$year <- factor(dat$year)
  dat$origin <- factor(dat$origin)
  ore.load(dsname)
  dat$PRED <- predict(cyl.mod.nb, newdata = dat,type="class")
  dat
}

# Store revised script in R Script Repository
ore.scriptList()
ore.scriptDrop("scoreNBmodel2")  # if doesn't exist, receive error
ore.scriptCreate("scoreNBmodel2",scoreNBmodel2)

# Verify function works from R with ore.rowApply
res4 <- ore.rowApply(
  AUTO[,1:8],
  FUN.NAME="scoreNBmodel2",
  dsname = "CYL_NB_MODEL_1",
  FUN.VALUE = res[[1]],
  rows=10,ore.connect=TRUE)

head(res4)

#########################
#    Random Red Dots    #
#########################

# Define function to plot numDots random numbers and return a
# data.frame with two columns and 10 rows

RandomRedDots <- function(numDots=100){
  id <- 1:10
  plot( 1:numDots, rnorm(numDots), pch = 21,
        bg = "red", cex = 2 )
  data.frame(id=id, val=id / 100)
}

# Invoke function from R client, see image and data.frame
RandomRedDots(500)

# Execute script at DB server, but with 200 dots
dev.off()

res <- NULL
res <- ore.doEval(RandomRedDots, numDots=200)
res

# Save the R script in DB R Script Repository
# with a specific name

ore.scriptDrop("RandomRedDots")
ore.scriptCreate("RandomRedDots",RandomRedDots)

# Execute script by name with only 50 dots

dev.off()

ore.doEval(FUN.NAME="RandomRedDots",numDots=50)

####################
###     STOP     ###
####################

#############################
### START OF SQL SECTION  ###
#############################

# GO TO SQL Developer to invoke from SQL as rquser

# select    *
#   from      table(rqRowEval( cursor(select "mpg","cylinders","displacement","horsepower","weight",
#                                     "acceleration","year","origin" from RQUSER2.AUTO),
#                              cursor(select 1 "ore.connect",'CYL_NB_MODEL_1' "dsname" from dual),
#                              'select 1 mpg, ''a'' cylinders, 1 displacement, 1 horsepower, 1 weight, 1 acceleration, ''aa'' year, ''a'' origin, ''a'' PRED from dual',
#                              10,
#                              'scoreNBmodel2'));


# Images / Structured Data / XML

# begin
# sys.rqScriptDrop('RandomRedDots');
# sys.rqScriptCreate('RandomRedDots',
#                    'function(){
#                    id <- 1:10
#                    plot( 1:100, rnorm(100), pch = 21,
#                    bg = "red", cex = 2, main="Random Red Dots" )
#                    data.frame(id=id, val=id / 100)
#                    }');
# end;
# /
#   
# -- Return image only as PNG BLOB, one per image per row
# -- Structured content not returned with PNG option
# 
# select    ID, IMAGE
# from      table(rqEval( NULL,'PNG','RandomRedDots'));
# 
# -- Return structured data only by specifying table definition
# 
# select    *
#   from      table(rqEval( NULL,'select 1 id, 1 val from dual','RandomRedDots'));
# 
# -- Return structured and image content within XML string
# 
# select    *
#   from      table(rqEval(NULL, 'XML', 'RandomRedDots'));


###########################
### END OF SQL SECTION  ###
###########################

# Back in R, invoke same function
# Remove previous graphics device
dev.off()

ore.doEval(FUN.NAME="RandomRedDots")

# Cleanup
ore.scriptDrop("RandomRedDots")
ore.scriptDrop("scoreNBmodel")
ore.scriptDrop("scoreNBmodel2")

ore.delete("CYL_NB_MODEL_1")

rm(list = ls()) 

ore.drop(table="CUST_LTV")
ore.drop(table="CUST_LTV_HIGH")

#################################################
## Sharing R Scripts
#################################################

# Create an R script for the current user
ore.scriptDrop("privateFunction")  # error if doesn't exist
ore.scriptCreate("privateFunction",
                 function(data, formula, ...) lm(formula, data, ...))

# Create a global R script available to any user

ore.scriptDrop("globalFunction", global=TRUE) # error is doesn't exist
ore.scriptCreate("globalFunction",
                 function(data, formula, ...) glm(formula=formula, data=data, ...),
                 global = TRUE)

# List R scripts
ore.scriptList()$NAME
ore.scriptList(pattern="Function", type="all")

# Load an R script to an R function object

ore.scriptLoad(name="privateFunction")
ore.scriptLoad(name="globalFunction", newname="privateFunction2")

privateFunction  # View the function body

privateFunction2 # View the function body

# Grant and revoke R script read privilege to and from public
ore.grant(name = "privateFunction", type = "rqscript")
ore.scriptList(type="grant")  # no longer private!

# Connect to RQUSER2 to see function
ore.disconnect()
ore.connect("rquser2", conn_string="OAA1", host= "localhost", password="rquser2", all=TRUE)

ore.scriptList()
ore.scriptList(pattern="Function",
               type="all")

# Invoke shared private function to build lm model on iris data
ore.doEval(FUN.NAME="privateFunction",FUN.OWNER="RQUSER",
           formula=Sepal.Length~., data=iris)

ore.scriptLoad("privateFunction",owner="RQUSER")
privateFunction   # view function body

# Reconnect to RQUSER to revoke privileges
ore.disconnect()
ore.connect("rquser", conn_string="OAA1", host= "localhost", password="rquser", all=TRUE)

ore.revoke(name = "privateFunction", type = "rqscript")
ore.scriptList(type="grant")   # No scripts are visible

# Connect to RQUSER2 to see function
ore.disconnect()
ore.connect("rquser2", conn_string="OAA1", host= "localhost", password="rquser2", all=TRUE)

# Try again to invoke shared private function to build lm model on iris data
ore.doEval(FUN.NAME="privateFunction",FUN.OWNER="RQUSER",    # ERROR - no privilege
           formula=Sepal.Length~., data=iris)

# Reconnect to RQUSER to clean up
ore.disconnect()
ore.connect("rquser", conn_string="OAA1", host= "localhost", password="rquser", all=TRUE)

# Drop an R script
ore.scriptList(type="all")[,1:2]

ore.scriptDrop("privateFunction")
ore.scriptDrop("globalFunction", global=TRUE)
ore.scriptList(type="all")[,1:2]

## Housekeeping
rm(list=ls())
ore.disconnect()


###########################################
## End of Script
###########################################

