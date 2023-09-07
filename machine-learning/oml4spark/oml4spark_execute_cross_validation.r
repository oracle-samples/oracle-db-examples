######################################################################
# oml4spark_execute_cross_validation.r
#
# This demo uses the “Ontime” Airline dataset from the Bureau of 
# Transportation Statistics, and we want to run classification models 
# to try to identify the best models to predict a cancelled flight. 
#
# The functions are capable of accepting R DataFrames, CSV files on HDFS, 
# HIVE/IMPALA tables, and Spark DataFrames (generated in the Spark Session 
# that OML4Spark is processing), as input for processing.
#
# The initial stage is used for balancing the Sample (50% ’0’s and 50% ’1’s) 
# to improve the ability of the different models on detecting the cancellations. 
# The final output is requested to be a maximum of 30,000 records
#
# The second stage uses the balanced data as input to run a test on several 
# classification models available in OML4Spark, using k-Fold 
# Cross-Validation with k=3
# 
# The final output is a list of the Models in descending order of the 
# statistic requested (in this case it was Acccuracy), and a chart of descending 
# Balanced Accuracy for the models
# 
# All processing is done on Spark by using OML4Spark’s interfaces to several 
# functions and SparkSQL as well
#
# About the Ontime Airline dataset: The database contains scheduled and actual 
# departure and arrival times reported by certified U.S. air carriers that 
# account for at least one percent of domestic scheduled passenger revenues 
# since 1987. The data is collected by the Office of Airline Information, 
# Bureau of Transportation Statistics (BTS) , and can be downloaded from 
# their site at 
# https://www.transtats.bts.gov/tables.asp?DB_ID=120&DB_Name=&DB_Short_Name=#
#
# Copyright (c) 2020 Oracle Corporation                               
# The Universal Permissive License (UPL), Version 1.0                 
#                                                                     
# https://oss.oracle.com/licenses/upl/                                
#                                                                     
#                                                                     
######################################################################

# Calls the OML4Spark libraries
library(ORCH)

# Create a new Spark Session
if (spark.connected()) spark.disconnect()
spark.connect('yarn', memory='9g', enableHive = TRUE)

# Connect to IMPALA
ore.connect(type='IMPALA',host='xxxxxxxx',user='oracle', port='21050', all=FALSE )
# Synchronize the Table ALLSTATE
ore.sync(table='ontime1m')
ore.attach()
# Check that the table is viewable
ore.ls()

# Show a sample of the data
head(ontime1m)

# Load functions written for Cross Validation using the OML4Spark facilities for
# manipulating Spark DataFrames
source ('~/oml4spark_function_create_balanced_input.r')
source ('~/oml4spark_function_run_cross_validation.r')

## Create a balanced Spark DF by smart sampling based on a specific formula

# Formula for Classification of whether a customer had any Insurance Claims
formula_class <- cancelled ~ distance + as.factor(month) + as.factor(year) + as.factor(dayofmonth) + as.factor(dayofweek) 

# Create a Balanced Spark DataFrame with 50/50 output, requesting sampling down to 90,000 rows in total
# The idea is to balance the target variable ANY_CLAIM (whether the customer had any insurance claims) is 50% '0's and 50% '1's
# The input to the function is the IMPALA table, the formula that will be used for model build, 
system.time({
  balancedData <- createBalancedInput(input_bal=ontime1m,
                                      formula_bal=formula_class, 
                                      reduceToFormula=TRUE,
                                      feedback = TRUE,
                                      sampleSize = 10000
  )
})

# Review the Spark DataFrame called "balancedData" before executing the Cross-Validation
# The global average proportion of having any claims is 0.5 (since we balanced the data)
balancedData$show()

# Execute a 3-fold Cross-Validation using the algorithms provided by OML4Spark and Spark MLlib
finalModelSelection <- runCrossValidation(input_xval=balancedData, 
                                          formula_xval=formula_class, 
                                          numKFolds=3, 
                                          selectedStatistic='Accuracy', 
                                          legend='',
                                          feedback = TRUE )


# Many detailed explanations of the different statistics printed can be 
# found at https://en.wikipedia.org/wiki/Evaluation_of_binary_classifiers
#
# The original statistic requested as the one for sorting was the Mathews Correlation Coefficient
# More information about the MCC at https://en.wikipedia.org/wiki/Matthews_correlation_coefficient 
print(as.data.frame(finalModelSelection[[4]]))

# Show the different components returned by the function
finalModelSelection

if (spark.connected()) spark.disconnect()
if (ore.is.connected()) ore.disconnect()


#####################################################
### END CROSS-VALIDATION BEST MODEL IDENTIFICATION    
#####################################################