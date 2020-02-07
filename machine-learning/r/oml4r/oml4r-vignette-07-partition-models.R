################################################
##
## Oracle Machine Learning for R Vignettes
##
## Partition Models
##
## (c) 2020 Oracle Corporation
##
################################################

# Oracle Machine Learning for R (ORE) 1.5.1 has the 
# ability to automatically build an ensemble model based on 
# partitions of the training data. This produces a single model
# object, which is also used for scoring. 
#
# We use the 'wine' data set which contains various attributes of 
# red and white wines and a corresponding 'quality' measure. 

# housekeeping
rm(list=ls())

# load ORE packages and create database connection
library(ORE)
options(ore.warn.order=FALSE)
ore.connect(user="rquser",
            conn_string="OAA1",
            host="localhost",
            password="rquser",
            all=TRUE)

#-- Create the data table 

dat <- read.csv("WINE.csv")

ore.drop(table="WINE")
ore.create(dat, table="WINE")

#-- Classification with partition models

row.names(WINE) <- WINE$color           # assign row names to enable row indexing for train/test samples

set.seed(seed=6218945)                  # enable reproducible results

n.rows        <- nrow(WINE)
random.sample <- sample(1:n.rows, ceiling(n.rows/2))       # train/test sampling
WINE.train    <- WINE[random.sample,]                      # sample in-database using row indexing
WINE.test     <- WINE[setdiff(1:n.rows,random.sample),]    

#-- Build Support Vector Machine classification model on the training data set, both red and white wine

mod.svm   <- ore.odmSVM(quality~.-pH-fixed.acidity, WINE.train, 
                        "classification",kernel.function="linear")

pred.svm  <- predict (mod.svm, WINE.test,"quality")  # predict wine quality on test data set

head(pred.svm,3)   # view the probability of each class and prediction

#-- Generate confusion matrix
#--    Note that 3 and 8 are not predicted

with(pred.svm, table(quality,PREDICTION, dnn = c("Actual","Predicted")))

#-- Build a Partitioned SVM model based on wine color
#--   Note the use of odm.settings argument

mod.svm2   <- ore.odmSVM(quality~.-pH-fixed.acidity, WINE.train, 
                         "classification",kernel.function="linear",
                         odm.settings=list(odms_partition_columns = "color"))

pred.svm2  <- predict (mod.svm2, WINE.test,"quality")  # predict wine quality on test data set

head(pred.svm2,3)     # view the probability of each class and prediction

#-- Generate confusion matrix
#--    Note that 3 and 4 are not predicted

with(pred.svm2, table(quality,PREDICTION, dnn = c("Actual","Predicted")))

partitions(mod.svm2)
summary(mod.svm2["red"])

# housekeeping

rm(list=ls())
ore.drop(table="WINE")
ore.disconnect()

###########################################
## End of Script
###########################################

