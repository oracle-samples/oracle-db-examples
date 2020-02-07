################################################
##
## Oracle Machine Learning for R Vignettes
##
## Regression Model
##
## (c) 2020 Oracle Corporation
##
################################################

# In this vignette, we explore a data set from Kaggle on house sales prediction and
# and build/score regression models to predict price in-database.
#
# We will highlight a few aspects of ORE: 
#
#   * Data Access - creating database tables from R data.frames
#   * Transparency Layer - preparing and exploring data that reside in Oracle Database
#   * Predictive Analytics - using several OAA algorithms, predict price
#   * Embedded R Execution - build finer-grained models, one per zipcode, at the database server

# Source data: https://www.kaggle.com/harlfoxem/housesalesprediction

# Load the ORE library
library(ORE)

# Turn off row ordering warnings
options(ore.warn.order=FALSE)

?ore.connect  # View documentation on ore.connect

# Create an ORE Connection - setting 'all=TRUE' loads metadata for all tables in 
#   schema as ore.frame objects
ore.connect(user="rquser",
            conn_string="OAA1",
            host="localhost",
            password="rquser",
            all=TRUE)

ore.ls()  # list available tables

rm(list = ls())   # housekeeping

#################################################
# Create a database table from a CSV file in R
#################################################

# *** NOTE: Skip this section if already done with Variable Selection vignette ***

setwd("~/ORE")
house <- read.csv("kc_house_data.csv")  # Kaggle data set

colnames(house) # Verify that data loaded correctly by reviewing column names and...
head(house)     # View a few rows
str(house)      # See the data types associated with columns and adjust

#-- Create database table resulting in ore.frame proxy R object

ore.drop(table="HOUSE1")           # Drop any pre-existing database table 
ore.create(house, table="HOUSE1")  # Create database table using data.frame
ore.ls(pattern="HOUSE1")           # List tables matching pattern

colnames(HOUSE1)  # Verify names of columns in table
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
HOUSE1$floors     <- as.factor(HOUSE1$floors)     # Convert floors from number to factor

ore.drop(table="HOUSE")            # Drop any pre-existing database table HOUSE
ore.create(HOUSE1, table="HOUSE")  # Create modified table using ore.frame
ore.ls(pattern="HOUSE")            # List tables matching pattern

colnames(HOUSE)  # Verify names of columns in table
head(HOUSE)   # View of few records in the table to verify proper import
HOUSE@desc    # View the data types of each variable

#################################################
## Prepare Data
#################################################

row.names(HOUSE) <- HOUSE$id  # Assign row names to enable row indexing

HOUSE$yr_renovated <- ifelse(HOUSE$yr_renovated!=0, HOUSE$yr_renovated, NA) # replace 0 with NA for missing
HOUSE$age          <- as.numeric(format(Sys.Date(),'%Y'))-HOUSE$yr_built  # create variable for house age

summary(HOUSE$price)
HOUSE$price        <- log(HOUSE$price)                                         # price is heavily skewed - use log transform
HOUSE$lat          <- HOUSE$lat - mean(HOUSE$lat,na.rm=TRUE)                   # subtract the mean (minor normalization)
HOUSE$sqft_living  <- HOUSE$sqft_living -  mean(HOUSE$sqft_living,na.rm=TRUE)  # subtract the mean (minor normalization)


###############################################################################
# Create Train and Test data sets in preparation for regression model building
###############################################################################

set.seed(1)   # enable repeatable results

sampleSize <- round(nrow(HOUSE) * 0.6)             # use 60% of data for training
ind        <- sample(1:nrow(HOUSE),sampleSize)     # get indexes of rows for training sample
group      <- as.integer(1:nrow(HOUSE) %in% ind)   # create group vector for row indexing sample

row.names(HOUSE) <- HOUSE$id                       # enable row indexing
HOUSE.train      <- HOUSE[group==TRUE,]            # get train sample, which remains in the database
dim(HOUSE.train)
class(HOUSE.train)

HOUSE.test <- HOUSE[group==FALSE,]                 # get test sample
dim(HOUSE.test)

############################################
# Define Regression Test Metrics functions
############################################

#-- Root Mean Square Error (RMSE)

ore.rmse <- function (pred, obs) {
  sqrt(mean((pred-obs)^2,na.rm=TRUE))
}

#-- RMSE and R-squared

ore.reg.stats <- function (predicted, actual) {
  y_mean <- mean(actual)
  res2 <- (actual - predicted)^2
  tot2 <- (actual - y_mean)^2
  SS_res <- sum(res2)
  SS_tot <- sum(tot2)
  n <- length(predicted)
  
  RMSE <- sqrt(SS_res/n)
  R2   <- 1 - SS_res/SS_tot

  data.frame(N=n, RMSE=RMSE, R2=R2)
}

##############################
# Build Models
##############################

#-- Use R's lm algorithms to build model on the client

hh.train <- ore.pull(HOUSE.train)  # pull data to client for open source R algorithm lm

hh.test  <- ore.pull(HOUSE.test)

# Using open source R's lm function, build a linear model to predict price, 
# while excluding several columns
mod.lm1 <- lm(price~.-id-date-zipcode-yr_renovated, hh.train)

summary(mod.lm1)  # View the coefficients and summary statistics of the model
plot(mod.lm1)     # View plot for understanding model quality and characteristics

# Rebuild model excluding NA variables: sqft_basement and yr_built (proxy for age)
mod.lm2 <- lm(price ~ ., data = subset(hh.train, 
                                      select = -c(id, date, zipcode, yr_renovated, sqft_basement, yr_built)))
summary(mod.lm2)  # View model coefficients and summary statistics

# Predict values
pred.lm2 <- predict(mod.lm2, subset(hh.test, 
                                  select = -c(id, date, zipcode, yr_renovated, sqft_basement, yr_built)))
head(pred.lm2)    # note that only predictions are returned
summary(pred.lm2) 

pred.lm2a <- data.frame(price=hh.test$price, output=pred.lm2) # construct data.frame with price

res.stats <- ore.reg.stats(pred.lm2a$output, pred.lm2a$price)  # compute broader statistics
(res.stats.summary <- data.frame(alg="lm",RMSE=res.stats$RMSE, R2=res.stats$R2))


#--ore.lm: build linear model using ORE's parallel distributed version of lm()

mod.ore.lm <- ore.lm(price~.-id-date-zipcode, HOUSE.train)
summary(mod.ore.lm)

# Rebuild model excluding NA variables from the previous build
mod.ore.lm <- ore.lm(price~., 
                     subset(HOUSE.train, 
                            select = -c(id, date, zipcode, yr_renovated, sqft_basement, yr_built)))
summary(mod.ore.lm)

# score data to predict price
pred.ore.lm <- predict(mod.ore.lm, HOUSE.test, supplemental.cols=c("id","price"))
head(pred.ore.lm)
summary(pred.ore.lm)

res.stats <- ore.reg.stats(pred.ore.lm$output, pred.ore.lm$price)  # compute broader statistics
res.stats.summary <- rbind(res.stats.summary,
                           data.frame(alg="ore.lm",RMSE=res.stats$RMSE, R2=res.stats$R2))
res.stats.summary # lm and ore.lm provide virtually the same results

#-- Build a Support Vector Machine regression model using ore.odmSVM

mod.svm <- ore.odmSVM(price~.-id-date-yr_built-zipcode-sqft_basement, HOUSE.train, "regression")
summary(mod.svm)

pred.svm <- predict(mod.svm, HOUSE.test, supplemental.cols=c("id","price"))
class(pred.svm)
head(pred.svm)
summary(pred.svm)

res.stats <- ore.reg.stats(pred.svm$PREDICTION, pred.svm$price)
res.stats.summary <- rbind(res.stats.summary,
                           data.frame(alg="ore.odmSVM",RMSE=res.stats$RMSE, R2=res.stats$R2))
res.stats.summary


#-- ore.odmGLM

mod.glm <- ore.odmGLM(price~.-id-date-yr_built-zipcode, HOUSE.train, 
                      auto.data.prep=TRUE, ridge=TRUE)
summary(mod.svm)

pred.glm <- predict(mod.glm, HOUSE.test, supplemental.cols=c("id","price"))
class(pred.glm)
head(pred.glm)
summary(pred.glm)

res.stats <- ore.reg.stats(pred.glm$PREDICTION, pred.glm$price)
res.stats.summary <- rbind(res.stats.summary,
                           data.frame(alg="ore.odmGLM",RMSE=res.stats$RMSE, R2=res.stats$R2))
res.stats.summary

#-- ore.neural

ore.rm(list="HOUSE2")          # perform some cleanup before creating new data table
ore.drop(table="HOUSE2")
ore.create(house, table="HOUSE2")
row.names(HOUSE2) <- HOUSE2$id

# Work with numeric variables only, scaled to work with neural network
nms <- setdiff(names(HOUSE2), c("id", "price"))   # exclude id and price from scaling

# use ORE scale function to scale all numeric columns
X <- as.ore.frame(lapply(nms, 
                         function(nm) 
                           if (is.numeric(HOUSE2[[nm]])) 
                             scale(HOUSE2[[nm]]) 
                         else HOUSE2[[nm]]))
names(X) <- nms

X <- cbind(id=HOUSE2$id, price=log(HOUSE2$price), X)   # add back in id and log(price)
range(X$price)

row.names(X) <- X$id                      # enable row indexing
sampleSize <- round(nrow(X) * 0.6)        # split data 60% - 40%
ind <- sample(1:nrow(X),sampleSize)
group <- as.integer(1:nrow(X) %in% ind)

HOUSE2.train <- X[group==TRUE,]           # produce the train and test sets
HOUSE2.test  <- X[group==FALSE,]

# remove unwanted columns from training data so all predictors are numeric
HOUSE2.train2 <- subset(HOUSE2.train, 
                        select = -c(id, date, yr_built, zipcode, sqft_basement)) 

# Build the neural network model, try some variables of the architecture
#    E.g., hiddenSizes (16,8,2) with activations ("sigmoid","sigmoid","sigmoid","linear")
mod2.nn <- NULL
mod2.nn <- ore.neural(price ~ .,
                      HOUSE2.train2,
                      hiddenSizes=c(10,5),
                      activations=c("sigmoid","sigmoid","linear"),
                      maxIterations=2000)

mod2.nn  # view model details

# leave column id in test data
HOUSE2.test2 <- subset(HOUSE2.test, select = -c(date, yr_built, zipcode, sqft_basement))  
pred2.nn <- predict(mod2.nn, HOUSE2.test2, supplemental.cols=c("id","price"))
head(pred2.nn, 10)

# compute statistics
res.stats <- ore.reg.stats(pred2.nn$pred_price, pred2.nn$price)
res.stats.summary <- rbind(res.stats.summary,
                           data.frame(alg="ore.neural",RMSE=res.stats$RMSE, R2=res.stats$R2))
res.stats.summary


###################################################################
# Embedded R Execution - database-side execution to return ranking
###################################################################

ore.delete("HousePriceModels") # remove previous datastore, if exists

res <- ore.groupApply(HOUSE,
                      HOUSE$zipcode,           # partition on zipcode
                      function (dat) {         # build model and save within unique name in datastore
                        mod  <- lm(price~age+lat+long+sqft_living+bedrooms+bathrooms, dat)
                        name <- paste("mod",dat$zipcode[1],sep="")
                        assign(name,mod)
                        try(ore.save(list=name,
                                     name="HousePriceModels",append=TRUE))
                        TRUE
                      }, ore.connect=TRUE)
res  # contains the 70 newly built models, one per zipcode

ore.datastore()                           # View the list of datastore entries
ore.datastoreSummary("HousePriceModels")  # View the contents of the datastore just created
ore.load("HousePriceModels")              # Load the objects into memory from the datastore

summary(mod98001)                         # View the summary of one zipcode's model

# housekeeping

ore.delete(name="HousePriceModels")       # Delete the datastore entry, and all contained models
rm(list=ls())
ore.drop(table="HOUSE")
ore.drop(table="HOUSE1")
ore.drop(table="HOUSE2")
ore.disconnect()

################################################
## End of Script
################################################


