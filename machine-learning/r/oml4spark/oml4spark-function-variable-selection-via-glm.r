##################################################################
# Function to create Variable Selection using Logistic Regression 
# analysis.  Variables are selected based on the Correlation to   
# Target                                                          
#                                                                 
# Usage: selectVariablesViaGLM2( formulaForCorr,                  
#                                inputForCorr,                    
#                                feedback = FALSE                    
#                               )                                     
#                                                                 
#                                                                 
# Copyright (c) 2020 Oracle Corporation                           
# The Universal Permissive License (UPL), Version 1.0             
#                                                                 
# https://oss.oracle.com/licenses/upl/                            
#                                                                 
##################################################################

################################################
### VARIABLE SELECTION WITH GLM2 THE TARGET  ###
################################################

### Logistic Regression for Variable Selection

## INPUT IS ORIGINAL DATASET AND FORMULA
## OPTIONAL INPUTS ARE: CUMULATIVE PERCENT VARIANCE EXPLANATION, CORRELATION 
selectVariablesViaGLM2 <- function(formulaForCorr, 
                                   inputForCorr, 
                                   feedback=FALSE )
{
  # Find the ideal number of Partitions to use when creating the Spark DF
  # To Maximize Spark parallel utilization
  sparkXinst <- as.numeric(spark.property('spark.executor.instances'))
  sparkXcores <- as.numeric(spark.property('spark.executor.cores'))
  ideal_partitions <- sparkXinst*sparkXcores
  
  # Verify verbose level  
  if (grepl(feedback, "FULL", fixed = TRUE)) 
  {verbose_user <- TRUE
  } else {verbose_user <- FALSE}
  
  # Push the INPUT DATA to Spark (if it's not already)
  # In Case it is a Spark DF already we don't do anything
  if (!((spark.connected()) && (class(inputForCorr)[1]=="jobjRef"))) {
    # Check if the input if a DFS ID (HDFS)
    if (is.hdfs.id(inputForCorr)) {
      if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is HDFS...processing')
      corr_df <- orch.df.fromCSV(inputForCorr, 
                                 minPartitions = ideal_partitions, 
                                 verbose = verbose_user ) # Convert the input HDFS to Spark DF
    } else
      # Check if the input is HIVE and load it into Spark DF
      if ( ore.is.connected(type='HIVE') && (is.ore.frame(inputForCorr)) ) {
        if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is HIVE Table...processing')
        corr_df <- ORCHcore:::.ora.getHiveDF(inputForCorr$sqlTable, 
                                             minPartitions = ideal_partitions, 
                                             verbose = verbose_user )
      } else
        # Check if the input is IMPALA
        if ( ore.is.connected(type='IMPALA') && (is.ore.frame(inputForCorr)) ) {
          if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is IMPALA Table...processing')
          corr_df <- ORCHcore:::.ora.getHiveDF(inputForCorr$sqlTable, 
                                               minPartitions = ideal_partitions, 
                                               verbose = verbose_user )
        } else
          # For R Dataframe it is a two-step process for now
          if (is.data.frame(inputForCorr)){
            if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is R Dataframe...processing')
            corr_hdfs <- hdfs.put(inputForCorr)
            corr_df <- orch.df.fromCSV(corr_hdfs, 
                                       minPartitions = ideal_partitions, 
                                       verbose = verbose_user ) # Convert the input HDFS to Spark DF
          }
  } else 
    # If it's already a Spark DF then just point to it
  { if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is already Spark DF')
    corr_df <- inputForCorr}
  
  # Persist the Spark DF for added performance
  orch.df.persist(corr_df, storageLevel = "MEMORY_ONLY", verbose = feedback)
  
  # Extract Original terms from formula
  formulaTerms <- terms(x=formulaForCorr, data=orch.df.collect(corr_df$limit(1L)))
  
  # Extract Var names from formula
  tempVars <- gsub(".*~","",Reduce(paste, deparse(formulaTerms)))
  tempVars <- gsub(" ", "", tempVars)
  tempVars <- gsub("-1","", tempVars)
  finalVarList <- strsplit( tempVars , "+", fixed = TRUE)[[1]]
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    print('List of Variables to Evaluate:')
    print(finalVarList)
  }
  
  ##################################
  # Study expansion for Interactions
  #
  allTerms <- character()
  for (i in 1:length(finalVarList)) allTerms <- rbind(allTerms,paste0(finalVarList[i],':',finalVarList))
  
  # Identify the numerical columns from the Data Frame, and reduce it to the columns included
  # in the formula
  numericalCols <- capture.output(corr_df$numericColumns())
  numericalCols <- gsub(".*\\(\\s*|\\).*", "", numericalCols)
  numericalCols <- unlist(strsplit(gsub("  "," ",trimws(gsub(targetFromFormula,"",
                                                             gsub("#.."," ",
                                                                  gsub("#..,"," ",numericalCols))))),
                                   split = " ", 
                                   fixed = TRUE))
  # Compare with columns in the formula
  numericalCols <- sapply(numericalCols, grepl, finalVarList, simplify = TRUE)
  # Final list of Numerical variables included in the formula
  numericalCols <- colnames(numericalCols[,(colSums(numericalCols)>0)])
  # Add squared items to the final formula
  squaredCols <- paste0('I(',numericalCols,'^2)')
  
  formula_expanded <- as.formula(paste(targetFromFormula,' ~ ',paste(c(squaredCols,allTerms),collapse = '+')))
  
  # Run a GLM2 Model
  model <- orch.glm2(formula_expanded, corr_df, verbose=verbose_user)
  
  # Capture the Summary Output allowing for up to 10,000 rows of coefficients
  options("max.print"=10000)
  summtxt <- capture.output(summary(model))
  # Restore the default 1,000 lines of output
  options("max.print"=1000)
  
  # Find the section of the Summary with the significance of the coefficients
  firstSectionHeader <- which(grepl(summtxt,pattern = "Pr(>",fixed = TRUE  ))
  lastSectionFooter <- which(grepl(summtxt,pattern = "---",fixed = TRUE  ))
  statTemp <- as.data.frame(summtxt[firstSectionHeader:(lastSectionFooter-1)])
  names(statTemp) <- " "
  # Get a list of the Variables without the Intercept
  limitedToVars <- as.character(statTemp[3:nrow(statTemp),])
  # Check for variable levels with at least 99% significance
  limitedToVars <- limitedToVars[sapply("[*]", grepl, limitedToVars)]
  
  listOfSignificantVars <- strsplit(limitedToVars, split = ':')
  
  identifyVars <- function(x) {
    firstVar <- sapply(finalVarList, grepl, x[1])
    firstVar <- names(firstVar[(firstVar>0)])
    if (length(x) > 1) {
      secondVar <-   sapply(finalVarList, grepl, strsplit(x[2],split = " ")[[1]][1])
      secondVar <- names(secondVar[(secondVar>0)])
      return(paste0(firstVar,':',secondVar))
    } else return(firstVar)
  }
  
  finalListOfVars <- unique(sapply(listOfSignificantVars, 
                                   identifyVars, 
                                   simplify=TRUE))
  
  
  originalVarsToAdd <- finalVarList[(colSums(sapply(finalVarList, 
                                                    grepl, 
                                                    finalListOfVars, 
                                                    fixed=TRUE))>0)]
  
  finalListOfVars <- unique(append(originalVarsToAdd,finalListOfVars))
  
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    cat('\n')
    cat(paste0('\n Total Set of ',length(finalListOfVars),' significant Variables and Interactions: \n'))
    print(as.character(finalListOfVars))
  }
  
  return(as.character(finalListOfVars))
}

