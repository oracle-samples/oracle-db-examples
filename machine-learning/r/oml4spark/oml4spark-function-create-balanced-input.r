###############################################################
# 2020_createBalancedInput.R                                   
# Function to create a Balanced Dataset based on Input         
# Dataset and formula.                                         
#                                                              
# Input can be HDFS ID, HIVE, IMPALA, Spark DF or R dataframe  
#                                                              
# It allows for a range to be choosen                          
# for the TARGET proportion so that if one thinks the          
# proportion is within that range, then the returned Spark DF  
# is the original input                                        
#                                                              
# Usage: createBalancedInput( input_bal ,                      
#                             formula_bal ,                    
#                             feedback = FALSE ,               
#                             rangeForNoProcess = c(0.45,0.55) 
#                           )                                  
#                                                              
#                                                              
# Copyright (c) 2020 Oracle Corporation                        
# The Universal Permissive License (UPL), Version 1.0          
#                                                              
# https://oss.oracle.com/licenses/upl/                         
#                                                              
###############################################################

#######################################
### GENERATE A BALANCED SAMPLE
### FROM ANY INPUT
### HDFS ID, SPARK, HIVE, R Dataframe
#######################################

createBalancedInput <- function(input_bal, formula_bal, reduceToFormula=FALSE, 
                                feedback = FALSE, rangeForNoProcess = c(0.45,0.55),
                                sampleSize = 0) {
  # Extract the Target variable from the formula
  targetFromFormula <- strsplit(deparse(formula_bal), " ")[[1]][1] 
  # If the Target has an "as.factor", remove it for processing
  if (startsWith(targetFromFormula,"as.factor(")) 
  { targetFromFormula <- regmatches(targetFromFormula,
                                    gregexpr("(?<=\\().+?(?=\\))", 
                                             targetFromFormula,
                                             perl = T))[[1]]
  }
  # If the user wants to run a full verbose mode, store the info
  if (grepl(feedback, "FULL", fixed = TRUE)) 
  {verbose_user <- TRUE
  } else {verbose_user <- FALSE}    
  
  # Find the ideal number of Partitions to use when creating the Spark DF
  # To Maximize Spark parallel utilization
  sparkXinst <- as.numeric(spark.property('spark.executor.instances'))
  sparkXcores <- as.numeric(spark.property('spark.executor.cores'))
  ideal_partitions <- sparkXinst*sparkXcores
  
  # Push the INPUT DATA to Spark (if it's not already)
  # In Case it is a Spark DF already we don't do anything
  if (!((spark.connected()) && (class(input_bal)[1]=="jobjRef"))) {
    # Check if the input if a DFS ID (HDFS)
    if (is.hdfs.id(input_bal)) {
      if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is HDFS...processing')
      dat_df <- orch.df.fromCSV(input_bal, 
                                minPartitions = ideal_partitions, 
                                verbose = FALSE ) # Convert the input HDFS to Spark DF
    } else
      # Check if the input is HIVE and load it into Spark DF
      if ( ore.is.connected(type='HIVE') && (is.ore.frame(input_bal)) ) {
        if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is HIVE Table...processing')
        dat_df <- ORCHcore:::.ora.getHiveDF(table=input_bal@sqlTable)
      } else
        # Check if the input is IMPALA
        if ( ore.is.connected(type='IMPALA') && (is.ore.frame(input_bal)) ) {
          if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is IMPALA Table...processing')
          dat_df <- ORCHcore:::.ora.getHiveDF(table=input_bal@sqlTable)
        } else
          # For R Dataframe it is a two-step process for now
          if (is.data.frame(input_bal)){
            if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is R Dataframe...processing')
            dat_hdfs <- hdfs.put(input_bal)
            dat_df <- orch.df.fromCSV(dat_hdfs, 
                                      minPartitions = ideal_partitions, 
                                      verbose = FALSE ) # Convert the input HDFS to Spark DF
          }
  } else 
    # If it's already a Spark DF then just point to it
  { if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) print('Input is already Spark DF')
    dat_df <- input_bal}
  
  # Persist the Spark DF for added performance
  orch.df.persist(dat_df, storageLevel = "MEMORY_ONLY", verbose = verbose_user)
  
  # Extract Original terms from formula to reduce the original Dataset (if indicated)
  formulaTerms <- terms(x=formula_bal, data=orch.df.collect(dat_df$limit(1L)))
  
  # Extract Var names from formula
  tempVars <- gsub(".*~","",Reduce(paste, deparse(formulaTerms)))
  tempVars <- gsub(" ", "", tempVars)
  tempVars <- gsub("-1","", tempVars)
  
  # Final list
  finalVarList <- strsplit( tempVars , "+", fixed = TRUE)[[1]]
  # In case the user added "as.factor()" to the variables
  removeAsFactor <- function(x) {
    if (startsWith(x,"as.factor(")) {
      regmatches(x, gregexpr("(?<=\\().+?(?=\\))", x, perl = T))[[1]]
    } else x
  }
  finalVarList <- unlist(lapply(finalVarList,removeAsFactor))
  
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) {
    print('List of Variables from Formula that are going to be in the output Spark DataFrame:')
    print(c(targetFromFormula,finalVarList))
  }
  
  if (reduceToFormula==TRUE) {
    # Select only the columns used by the formula plus the target
    dat_df <- dat_df$selectExpr(append(targetFromFormula,finalVarList))
    # Persist the Reduced Spark DF for added performance
    orch.df.persist(dat_df, storageLevel = "MEMORY_ONLY", verbose = verbose_user)
  }
  
  # Prepare to create a SQL View with random name for the Spark DF
  op <- options(digits.secs = 6)
  time <- as.character(Sys.time())
  options(op)
  tempViewName <- paste0("tmp_view_",
                         paste(regmatches(time,
                                          gregexpr('\\(?[0-9]+', 
                                                   time))[[1]],
                               collapse = ''), 
                         collapse = " ")
  orch.df.createView(dat_df , tempViewName)
  
  # Capture the proportion of Target=1 in order to balance the Data into 50/50
  targetInfo <- orch.df.collect(orch.df.sql(paste0("select ",targetFromFormula,
                                                   " as target, count(*) as num_rows from ",
                                                   tempViewName," group by ",targetFromFormula, 
                                                   " order by ",targetFromFormula)))
  proportionTarget <- targetInfo[2,2]/sum(targetInfo$num_rows)
  # Not needed, maybe future use:  names(proportionTarget) <- c(as.character(targetInfo[2,1]),as.character(targetInfo[1,1]))
  
  # Only need to Sample from Target = 0 if the proportion is outside of the Range given by the user.
  # Default is 0.45 to 0.55, so if the proportion is already close enough to 0.5 we should not waste time sampling
  if (findInterval(proportionTarget, rangeForNoProcess)) {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) 
      cat(paste0('\nTarget proportion in Input Data already within range ',
                 paste0(rangeForNoProcess, collapse = ' <-> '),' . No change done. \nTarget proportion is : ', 
                 format(proportionTarget,digits=6), '\nNum Rows is : ',format(sum(targetInfo$num_rows),big.mark=',')))
    balanced <- dat_df 
  } else {
    cat(paste0('\nTarget proportion is outside the range ',paste0(rangeForNoProcess, collapse = ' <-> '),
               ' . Processing...\nTarget proportion is : ', format(proportionTarget,digits=6)))
    # Select all Target = 1 records and put them into a Spark DF "input_1"
    input_1 <- dat_df$filter(c(paste0(targetFromFormula," == '",targetInfo$target[which.min(targetInfo$num_rows)],"'")))
    target_1_count <- targetInfo[2,2] # or input_1$count()
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat(paste0('\nTarget = ',targetInfo[2,1],' count : ', 
                                                               format(target_1_count,big.mark = ",")))
    
    # Select a sample of Target = 0 records and put them into a Spark DF "input_0"
    input_0 <- dat_df$filter(c(paste0(targetFromFormula," == '",targetInfo$target[which.max(targetInfo$num_rows)],"'")))
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat(paste0('\nTarget = ',targetInfo[1,1],' count : ', 
                                                               format(targetInfo[1,2],big.mark = ","))) # or input_0$count()
    
    # Prepare the settings needed for the Sampling function of Spark on Data Frames "$sample"
    samp_rate <- min(1,targetInfo[2,2]/targetInfo[1,2])
    seed_long <- .jlong(12345L)
    # Runs the sample of Target = 0 records a little bigger (with an offset) to avoid limitations 
    # by Spark DF "$sample" function sometimes sampling smaller than desired samples
    offset <- 10*(1/target_1_count)
    if ((samp_rate+offset)>=1) {offset <- 1 - samp_rate -0.01}
    sample_0 <- input_0$sample(FALSE,samp_rate+offset,seed_long)
    
    # Trims the sample of Target = 0 records to the ideal size (same as te target = 1) using the function "$limit"
    input_0_samp <- sample_0$limit(as.integer(target_1_count))
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat(paste0('\nSampled Target = ',
                                                               targetInfo[1,1],' count : ', 
                                                               format(input_0_samp$count(),big.mark = ",")))
    
    # Use the function "$union" from Spark Data Frame to join both Target and non-Target portions 
    balanced <- input_1$union(input_0_samp)
    
    if (sampleSize >0) {
      newSampRate <- (sampleSize/balanced$count())
      if (newSampRate < 1) {
        if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat(paste0('\nSampling final balanced count from ',
                                                                   format(balanced$count(),big.mark = ","),' down to ',
                                                                   format(sampleSize,big.mark = ","),' records'))
        sample_final <- balanced$sample(FALSE,newSampRate+offset,seed_long)
        balanced <- sample_final$limit(as.integer(sampleSize))
        orch.df.unpersist(sample_final)
      } else {
        if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat(paste0('\nSampling requested of ',
                                                                   format(sampleSize,big.mark = ","),
                                                                   ' is larger than final balanced count and was ignored.'
        ))
      }
    }
    
    orch.df.unpersist(dat_df)
    orch.df.unpersist(input_1)
    orch.df.unpersist(input_0)
    orch.df.unpersist(input_0_samp)
    orch.df.persist(balanced, storageLevel = 'MEMORY_ONLY', verbose = FALSE)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat(paste0('\nBalanced Final count : ', 
                                                               format(balanced$count(),big.mark = ","),
                                                               '\n'))
  }
  return(balanced)
}