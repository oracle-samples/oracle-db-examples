######################################################################
# 2020_runCrossValidation.R                                           
# Function to run a k-Fold Cross-Validation using all ORAAH           
# classification algorithms available                                       
#                                                                     
# Process a Balanced Dataset based on Input                           
# Dataset and formula.                                                
#                                                                     
# Input can be HDFS ID, HIVE, IMPALA, Spark DF or R dataframe         
#                                                                     
# Usage: runCrossValidation ( input_xva ,                             
#                             formula_xval ,                          
#                             numKFolds = 3 ,                         
#                             selectedStatistic = 'MathewsCorrCoef' , 
#                             feedback = FALSE ,                      
#                             legend = ' '                            
#                           )                                         
#                                                                     
# Copyright (c) 2020 Oracle Corporation                               
# The Universal Permissive License (UPL), Version 1.0                 
#                                                                     
# https://oss.oracle.com/licenses/upl/                                
#                                                                     
#                                                                     
######################################################################

#######################################
### RUN CROSS-VALIDATION ANALYSIS OF
### MODELS FROM A SPARK DF INPUT
#######################################
# input_xval=balancedData
# formula_xval=formula_class
# numKFolds=3
# selectedStatistic='MathewsCorrCoef'
# feedback = TRUE
# legend=' '

runCrossValidation <- function(input_xval, formula_xval, numKFolds=3, selectedStatistic='MathewsCorrCoef', legend=' ', feedback=FALSE ) {
  
  # Load functions required
  source ('~/R_scripts/2020_confusionMatrixInSpark.R')
  source ('~/R_scripts/2020_buildAllClassificationModels.R')
  
  if (grepl(feedback, "FULL", fixed = TRUE)) 
  {verbose_user <- TRUE
  } else {verbose_user <- FALSE}    
  # Create a list of K identical proportions for the number of splits required
  splitProps <- rep(1/numKFolds, times = numKFolds) 
  splits <- .jarray(splitProps)
  seed <- .jlong(12345678L)
  
  # Find the ideal number of Partitions to use when creating the Spark DF
  # To Maximize Spark parallel utilization
  sparkXinst <- as.numeric(spark.property('spark.executor.instances'))
  sparkXcores <- as.numeric(spark.property('spark.executor.cores'))
  ideal_partitions <- sparkXinst*sparkXcores
  
  # Push the INPUT DATA to Spark (if it's not already)
  # In Case it is a Spark DF already we don't do anything
  if (!((spark.connected()) && (class(input_xval)[1]=="jobjRef"))) {
    # Check if the input if a DFS ID (HDFS)
    if (is.hdfs.id(input_xval)) {
      if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is HDFS...processing')
      xval_df <- orch.df.fromCSV(input_xval, 
                                 minPartitions = ideal_partitions, 
                                 verbose = verbose_user ) # Convert the input HDFS to Spark DF
    } else
      # Check if the input is HIVE and load it into Spark DF
      if ( ore.is.connected(type='HIVE') && (is.ore.frame(input_xval)) ) {
        if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is HIVE Table...processing')
        xval_df <- ORCHcore:::.ora.getHiveDF(input_xval@sqlTable)
      } else
        # Check if the input is IMPALA
        if ( ore.is.connected(type='IMPALA') && (is.ore.frame(input_xval)) ) {
          if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is IMPALA Table...processing')
          xval_df <- ORCHcore:::.ora.getHiveDF(input_xval@sqlTable)
        } else
          # For R Dataframe it is a two-step process for now
          if (is.data.frame(input_xval)){
            if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is R Dataframe...processing')
            xval_hdfs <- hdfs.put(input_xval)
            xval_df <- orch.df.fromCSV(xval_hdfs, 
                                       minPartitions = ideal_partitions, 
                                       verbose = verbose_user ) # Convert the input HDFS to Spark DF
          }
  } else 
    # If it's already a Spark DF then just point to it
  { if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is already Spark DF')
    xval_df <- input_xval}
  
  # Persist the Spark DF for added performance
  orch.df.persist(xval_df, storageLevel = "MEMORY_ONLY", verbose = verbose_user)
  
  # Split Randomly as a list of K Spark DataFrames
  inputDataSplit <- xval_df$randomSplitAsList( splits , seed)
  # Not super precise....
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) 
    for (i in 1:numKFolds) {print(paste0('Records on K-Fold Slice # ',i,' : ',
                                         inputDataSplit$get(as.integer(i-1))$count()))
    }
  
  # Cross-Validation Loop will result in a list of Statistics from all Models
  allStats <- list()
  # For each slice of the k-Fold Cross Validation
  for (i in 1:numKFolds) {
    # Take the i-th slice of the Data and use it as Test
    testFold <- inputDataSplit$get(as.integer(i-1))
    # Take the rest of the Splits and apply a UNION on them all to build the Training
    buildFolds <- NULL
    for (j in 1:numKFolds) { 
      if (!i==j) {
        if (length(buildFolds) < 1) {
          buildFolds <- inputDataSplit$get(as.integer(j-1))
        } else {buildFolds <- buildFolds$union(inputDataSplit$get(as.integer(j-1))) }
      }
    } 
    # Return the counts on the Training and Test datasets
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
      cat('\nCross-Validation Fold # : ',i)
      cat('\nTraining is : ',buildFolds$count())
      cat('\nTest is : ',testFold$count())
      cat('\nBuilding Models...\n')}
    # Build all Models using the Training and Test
    allClassModels <- list()
    allClassModels <-  buildAllClassificationModels(INPUT_DATA=buildFolds,
                                                    TEST_DATA=testFold,
                                                    formula_class=formula_xval,
                                                    legend=legend,
                                                    feedback=feedback)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('\nComputing Stats...\n')
    # Compute Statistics using the Predictions to create a Confusion Matrix
    allStats[[i]] <- lapply(allClassModels,confusionMatrixInSpark)
  }
  # Available Statistics are
  availableStats <- c('BuildTime','ScoreTime','TP','FP','TN','FN','TPR','FPR','FNR','TNR',
                      'Precision','Accuracy','AUC','PPV',
                      'NPV','DetectionRate','DetectionPrevalence',
                      'BalancedAccuracy','F1Score','Informedness',
                      'MathewsCorrCoef')
  
  # IDENTIFYING the requested Statistic to use as the best   
  ixdStat <- which(availableStats==selectedStatistic)
  # EXTRACT the requested Statistic from All Runs on a Data Frame
  cumStats <- data.frame()
  # Extract the Statistic from each Model into the Data Frame
  # (sapply goes from 1:9 Models without LASSO)
  for (j in 1:numKFolds) {
    cumStats <- rbind(cumStats, as.numeric(sapply(1:length(allStats[[1]]), function(i) 
      paste(allStats[[j]][[i]][[3]][1,ixdStat]), simplify = TRUE)))
  }
  # Use the Model names as Column Names
  # (sapply goes from 1:9 Models without LASSO)
  names(cumStats) <- sapply(1:length(allStats[[1]]), 
                            function(i) paste(allStats[[1]][[i]][1]), simplify = TRUE)
  # Compute Average of the Selected Statistic across all k-Folds
  finalStatXValidation <- sapply(cumStats,mean)
  # Identify the Best Model Index (maximum Average Statistic)
  idxBestModel <- which.max(finalStatXValidation)
  # Sort Descending of the Selected Statistic Averages
  sortedFinalStatXValidation <-sort(finalStatXValidation, decreasing = TRUE)
  
  # Capture the Average of all K-Folds for each Model
  # (sapply goes from 1:9 Models without LASSO)
  cumAllStats <- t(sapply(1:length(allStats[[1]]), function(m)  
  { allRunsModel <- data.frame()
  allRunsModel <- as.data.frame(t(sapply(1:numKFolds,
                                         function(f) as.numeric(allStats[[f]][[m]][[3]]),
                                         simplify = TRUE)))
  names(allRunsModel) <- availableStats
  return(sapply(allRunsModel, function(l) formatC(mean(l),format='fg', digits=4), simplify = TRUE))  
  }, simplify=TRUE) )
  
  # Add the Model Names
  # (sapply goes from 1:9 Models without LASSO)
  cumAllStats <- cbind(sapply(1:length(allStats[[1]]), function(i) paste(allStats[[1]][[i]][1]), 
                              simplify = TRUE),
                       cumAllStats)
  
  # Sort the entire resulting Dataset using the desired Column
  sortedcumAllStats <-cumAllStats[(sort(cumAllStats[,ixdStat], 
                                        decreasing = TRUE, 
                                        index.return = TRUE))$ix,]
  
  return(list(finalStatXValidation,
              idxBestModel,
              sortedFinalStatXValidation,
              sortedcumAllStats))
}

#####################################################
### END CROSS-VALIDATION BEST MODEL IDENTIFICATION    
#####################################################