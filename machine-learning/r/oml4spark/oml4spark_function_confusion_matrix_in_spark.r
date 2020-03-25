###############################################################
# oml4spark_function_confusion_matrix_in_spark.r
# 
# Function to Compute a Confusion Matrix based on Spark SQL    
# given a Dataset that contains Actuals and Predicted          
#                                                              
# Usage: createBalancedInput( input_bal ,                      
#                             formula_bal ,                    
#                             feedback = FALSE ,               
#                             rangeForNoProcess = c(0.45,0.55) 
#                           )                                  
#                                                              
# Copyright (c) 2020 Oracle Corporation                        
# The Universal Permissive License (UPL), Version 1.0          
#                                                              
# https://oss.oracle.com/licenses/upl/                         
#                                                              
#                                                              
###############################################################

########################################################################################
### COMPUTING A CONFUSION MATRIX FOR BINARY CLASSIFIERS IN-MEMORY IN SPARK VIA OML4Spark ###
########################################################################################
confusionMatrixInSpark <- function(list_of_model_pred) {
  model <- list_of_model_pred[[1]]
  predictions <- list_of_model_pred[[2]]
  model_name <- list_of_model_pred[[3]]
  model_timings <- list_of_model_pred[[4]]
  # Initialize output
  allStats <- list()
  # Check original Target column from Model
  targetFromFormula <- strsplit(model$formula, " ")[[1]][1]
  # Remove as.factor() if it is present
  if (startsWith(targetFromFormula,"as.factor(")) { 
    targetFromFormula <- regmatches(targetFromFormula, 
                                    gregexpr("(?<=\\().+?(?=\\))",
                                             targetFromFormula,perl = T))[[1]]
  }
  
  # Persist the Scoring Data for added performance
  orch.df.persist(predictions,storageLevel = "MEMORY_ONLY",verbose = FALSE)
  
  # From all columns of the Predictions
  predAllColumns <- predictions$columns()
  # Capture Predictions and Probabilities
  if (!is.null(model$call)) {
    # Capture the Probability column
    predLastColumn <- ""
    if (predAllColumns[length(predAllColumns)]=='prediction2') {
      probLastColumn <- "prediction2"
    } else { probLastColumn <- "prediction" }
    
  } else {
    # Gather the Last column which is usually the Predicted Label for some models...
    predLastColumn <- predAllColumns[length(predAllColumns)]
    # ...and the last columns with Probability in the name which is usually the P(target)
    # with the exception of LASSO, which is
    if (attr(model,"class")=="orch.ml.lasso") { probLastColumn <- predLastColumn 
    } else {
      probColumns <- grep("probability", predAllColumns)
      probLastColumn <- predAllColumns[probColumns[length(probColumns)]]
    } 
  } 
  
  # Create Temporary View of original Dataset
  op <- options(digits.secs = 6)
  time <- as.character(Sys.time())
  options(op)
  tempViewName <- paste0("tmp_view_",
                         paste(regmatches(time,gregexpr('\\(?[0-9]+', time))[[1]],collapse = ''), 
                         collapse = " ")
  
  orch.df.createView(predictions , tempViewName)
  
  # If the Model includes Probabilities, get general statistics from the Prediction Data
  # in particular the proportion of Target=1 if model returns Probability
  targetInfo <- orch.df.collect(orch.df.sql(paste0("select ",targetFromFormula," as target, count(*) as num_rows from ",tempViewName," group by ",targetFromFormula, " order by ",targetFromFormula)))
  proportionTarget <- targetInfo[2,2]/sum(targetInfo$num_rows)
  
  # confMtxStructure is the structure of a Confusion Matrix for a traditional Binary Target Model
  confMtxStructure <- cbind(predicted=c(1,1,0,0),rbind(targetInfo[1],targetInfo[1]))
  colnames(confMtxStructure)[2] <- 'actual'
  # confusionComputed will compute the actual data from the Predicted column
  if (length(probLastColumn)>0) {
    confusionComputed <- orch.df.collect(orch.df.sql(paste0("select predicted, ",targetFromFormula,
                                                            " as actual, count(*) as count from (select ",
                                                            targetFromFormula," , case when `",probLastColumn,"` > ",proportionTarget,
                                                            " then 1 else 0 end as predicted from ",tempViewName,") group by ",
                                                            targetFromFormula," , predicted")))
  } else {
    # Check if model is ELM then response is the label and not 0/1
    predInfo <- orch.df.collect(orch.df.sql(paste0("select ",predLastColumn," as target from ",tempViewName," group by ",predLastColumn, " order by ",predLastColumn)))
    if (predInfo[2,]=='1') {
      confusionComputed <- orch.df.collect(orch.df.sql(paste0("select predicted, ",targetFromFormula,
                                                              " as actual, count(*) as count from (select ",
                                                              targetFromFormula," , case when ",
                                                              predLastColumn," == 1 then 1 else 0 end as predicted from ",
                                                              tempViewName,") group by ",
                                                              targetFromFormula," , predicted")))
    } else {
      confusionComputed <- orch.df.collect(orch.df.sql(paste0("select predicted, ",targetFromFormula,
                                                              " as actual, count(*) as count from (select ",
                                                              targetFromFormula," , case when ",
                                                              predLastColumn," == '",predInfo[2,],"' then 1 else 0 end as predicted from ",
                                                              tempViewName,") group by ",
                                                              targetFromFormula," , predicted")))
      
    }
  }
  
  # confusionMatrixFinal is the final structured Matrix with '0's replacing any NA
  confusionMatrixFinal <- merge(confMtxStructure,confusionComputed, by=c('predicted','actual'), all = TRUE)
  confusionMatrixFinal[is.na(confusionMatrixFinal)] <- 0
  
  # Adding Percentage
  confusionMatrixFinal$percentage <- confusionMatrixFinal$count/sum(confusionMatrixFinal$count)
  
  # Preparing for several statistics based on the Confusion Matrix
  # See https://en.wikipedia.org/wiki/Sensitivity_and_specificity
  # Also https://en.wikipedia.org/wiki/Matthews_correlation_coefficient
  
  # Compute True Positive, True Negative, False Positives and False Negatives
  TP <- confusionMatrixFinal$percentage[4] 
  FP <- confusionMatrixFinal$percentage[3] 
  TN <- confusionMatrixFinal$percentage[1] 
  FN <- confusionMatrixFinal$percentage[2] 
  
  TPR <- TP/(TP+FN)     # True Positive Rate - Sensitivity - Recall
  FPR <- FP/(FP+TN)     # False Positive Rate
  FNR <- FN/(FN+TP)     # False Negative Rate
  TNR <- TN/(TN+FP)     # True Negative Rate - Specificity
  Precision = TP/(TP+FP) # Precision
  Accuracy = (TP+TN)/(TP+TN+FP+FN) # Accuracy
  # Approximate AUC using Triangles
  AUC <- (1/2)*FPR*TPR + (1/2)*(1-FPR)*(1-TPR) + (1-FPR)*TPR
  # Prevalence <- (TP+FN)/(TP+TN+FP+FN) # Prevalence is a constant for all Models
  PPV <- Precision # Positive Predictive Value
  NPV <- TN/(FN+TN) # Negative Predictive Value
  DetectionRate <- TP/(TP+TN+FP+FN) # Detection Rate
  DetectionPrevalence <- Accuracy # Detection Prevalence
  BalancedAccuracy <- (TPR+TNR)/2  # Balanced Accuracy
  F1Score <- 2*Precision*TPR/(Precision+TPR) # F1 Score
  Informedness <- TPR+TNR-1 # Informedness
  MathewsCorrCoef <- ((TP*TN)-(FP*FN))/sqrt((TP+FP)*(TP+FN)*(TN+FP)*(TN+FN)) # Mathews Correlation Coefficient
  
  allStats <- list(model_name,
                   confusionMatrixFinal,
                   cbind(BuildTime=model_timings[1],ScoreTime=model_timings[3],
                         TP,FP,TN,FN,TPR,FPR,FNR,TNR,
                         Precision,Accuracy,AUC,PPV,NPV,DetectionRate,
                         DetectionPrevalence,BalancedAccuracy,F1Score,
                         Informedness,MathewsCorrCoef))
  return(allStats)
}

######### END OF CONFUSION MATRIX ANALYSIS