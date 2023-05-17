###############################################################
# Function to create Variable Selection using only SVD based   
# analysis.  Variables are selected based on the Total         
# Variability of any Normally-scaled variable                  
# given a Dataset          
#                                                              
# Usage: selectVariablesViaSVD ( formulaForSVD ,                      
#                                inputForSVD ,                    
#                                feedback = FALSE ,               
#                                varianceExplainedCutoff=0.90,
#                                minSignificanceEigenVectors = 0.20 
#                               )                                  
#                                                              
# Copyright (c) 2020 Oracle Corporation                        
# The Universal Permissive License (UPL), Version 1.0          
#                                                              
# https://oss.oracle.com/licenses/upl/                         
#                                                              
###############################################################

##########################################################
### VARIABLE SELECTION WITH SINGLE VALUE DECOMPOSITION ###
### WITH SUPPORT FOR NUMERICALS AND FACTORS            ###
### ONLY BASED ON OVERALL VARIABILITY, NOT THE TARGET  ###
##########################################################

### Principal Components Analysis for Variable Selection

## INPUT IS ORIGINAL DATASET AND FORMULA
## OPTIONAL INPUTS ARE: CUMULATIVE PERCENT VARIANCE EXPLANATION, CORRELATION 
selectVariablesViaSVD <- function(formulaForSVD, 
                                  inputForSVD, 
                                  feedback=FALSE, 
                                  varianceExplainedCutoff=0.90 ,   
                                  minSignificanceEigenVectors = 0.20 )
{
  
  formulaForSVD <- paste0('~ ',gsub(".*~","",Reduce(paste, deparse(formulaForSVD))))
  
  if (!(grepl(Reduce(paste, deparse(formulaForSVD)),"-1"))) {
    formulaForSVD <- paste0(formulaForSVD," -1")
  }
  
  if (grepl(feedback, "FULL", fixed = TRUE)) 
  {verbose_user <- TRUE
  } else {verbose_user <- FALSE}
  
  dmm <- orch.model.matrix(formulaForSVD, data=inputForSVD, 
                           type = 'dmm', factorMode = "none", 
                           verbose = verbose_user)
  
  eigenVectorNames <- dmm$getCoefName()
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    cat('\n')
    cat(paste0('\n ',length(eigenVectorNames),' total Eigenvector Levels\n'))
    print(eigenVectorNames)
  }  
  
  # Build the PCA Model asking for 10 Components
  
  # Need to scale variables first.
  scaledData <- orch.df.scale(data=inputForSVD, method = 'unitization_zero_minimum')
  # Review the Scaled Data
  scaledData$show(5L)
  
  # Run the PCA requesting up to 100 Components
  model_dspca <- orch.dspca(formula = formulaForSVD, data=scaledData, 
                            k = min(length(eigenVectorNames),100), 
                            formU = FALSE,
                            verbose = verbose_user)
  
  # Get the coefficients and output
  coef_pca <- coef(model_dspca)
  
  # Capture Partial Eigenvalues
  eigenValues <- coef_pca$s
  
  # Number of computed SVD Components
  numComputedComponents <- length(eigenValues)
  
  # IF necessary, let's complement the rest of the estimated Eigenvalues
  # by using an Exponential Decay (-log) to simulate the rest of the Eigenvalues
  if (numComputedComponents < length(eigenVectorNames)) {
    numTotalVariables <- length(eigenVectorNames)
    # Build the Log Range necessary based on Number of Eigenvalues
    logRange <- abs(-log(numTotalVariables-numComputedComponents))
    # Fill-in the rest of the Eigenvalues with the decay values which go to 0.
    eigenValues[(numComputedComponents+1):numTotalVariables] <- -log(1:(numTotalVariables-numComputedComponents))*
      eigenValues[numComputedComponents]/logRange+
      eigenValues[numComputedComponents]
    # Preview the Eigenvalues + Computed numbers
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
      cat('\n')
      cat(paste0('\n ',numComputedComponents,' Total Eigenvalues + Computed Eigenvalues \n'))
      print(eigenValues)
    }
  } else {
    # Preview the Eigenvalues numbers
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
      cat('\n')
      cat(paste0('\n ',numComputedComponents,' Total Eigenvalues \n'))
      print(eigenValues)
    }  
    
  }
  
  # Compute the proportion of variance explained by each of the original Eigenvalues
  propVarianceExplainedEigenValues <- eigenValues^2/sum(eigenValues^2)
  # Preview the Eigenvalues numbers
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    cat('\n')
    cat(paste0('\n ',length(propVarianceExplainedEigenValues),
               ' Proportions of Variance Explained by Eigenvalues and Scree Plot \n'))
    print(propVarianceExplainedEigenValues)
    plot(propVarianceExplainedEigenValues)
  }  
  
  # Evaluate the cumulative Sum of the Variance Explained
  evaluationVariance <- cumsum(propVarianceExplainedEigenValues)
  EigenvaluesIdx <- which(evaluationVariance<=varianceExplainedCutoff)
  reducedEigenvaluesIdx <- c(EigenvaluesIdx, (length(EigenvaluesIdx)+1))
  
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    cat('\n')
    cat(paste0('\n ',length(reducedEigenvaluesIdx),
               ' Reduced Number of Eigenvalues with a minimum of ',
               varianceExplainedCutoff*100,' % of Total Cumulative Variance \n'))
    print(formatC(propVarianceExplainedEigenValues[reducedEigenvaluesIdx],format='fg', digits=4))
    print(formatC(evaluationVariance[reducedEigenvaluesIdx],format='fg', digits=4))
  }  
  
  # Capture the final Eigenvectors
  eigenVectors <- as.matrix(coef_pca$V)
  # Apply the names of the Vectors
  row.names(eigenVectors) <- eigenVectorNames
  
  # From EigenVectors, select the Reduced Set
  significantVectors <- eigenVectors[,1:length(reducedEigenvaluesIdx)]
  
  finalListSignificantLevels <- character()
  for (x in 1:length(eigenVectorNames)) {
    if (any(abs(significantVectors[x,]) >= minSignificanceEigenVectors)) {
      finalListSignificantLevels <- rbind(finalListSignificantLevels,as.character(eigenVectorNames[x]))
    }
  }
  finalListSignificantLevels <- as.character(finalListSignificantLevels)
  
  # Print the list of Levels found significant
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    cat('\n')
    cat(paste0('\n ',length(finalListSignificantLevels),
               ' Reduced Number of Levels \n'))
    print(as.character(finalListSignificantLevels))
  }
  originalColumnNames <- scaledData$columns()
  
  # Look for the matching Columns used from the original Dataset
  matchingCols <- as.data.frame(sapply(originalColumnNames, grepl, 
                                       as.character(finalListSignificantLevels), 
                                       ignore.case=TRUE))
  
  # Get the final list of significant columns
  finalListSignificantVars <- colnames(matchingCols[,(colSums(matchingCols)>0)])
  
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    cat('\n')
    cat(paste0('\n ',length(finalListSignificantVars),
               ' Reduced Set of Variables \n'))
    print(as.character(finalListSignificantVars))
  }
  
  return(as.character(finalListSignificantVars))
  
}
