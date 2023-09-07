###############################################################
# oml4spark_function_build_all_classification_models.r
#
# Function to Build all classification Models available in     
# OML4Spark and export their predictions against a given TEST data 
# provided                                                     
#                                                              
# Input can be HDFS ID, HIVE, IMPALA, Spark DF or R dataframe  
#                                                              
# Usage: buildAllClassificationModels( INPUT_DATA ,            
#                                      TEST_DATA ,             
#                                      formula_class           
#                                      prop = NULL ,           
#                                      legend = '' ,           
#                                      feedback = FALSE ,      
#                                     )                        
#                                                              
#                                                              
# Copyright (c) 2020 Oracle Corporation                        
# The Universal Permissive License (UPL), Version 1.0          
#                                                              
# https://oss.oracle.com/licenses/upl/                         
#                                                              
###############################################################

##################################################################
### BUILDING ALL POSSIBLE BINARY CLASSIFICATION MODELS WITH OML4Spark
##################################################################
# INPUT_DATA=buildFolds
# TEST_DATA=testFold
# formula_class=formula_xval
# feedback=feedback
# formula_class <- CANCELLED ~ DISTANCE + as.factor(MONTH) + as.factor(YEAR) + as.factor(DAYOFWEEK) + as.factor(DAYOFMONTH) + as.factor(FLIGHTNUM)

buildAllClassificationModels <- function(INPUT_DATA,TEST_DATA, formula_class, 
                                         prop=NULL, legend='', feedback=FALSE) {
  
  if (grepl(feedback, "FULL", fixed = TRUE)) 
  {verbose_user <- TRUE
  } else {verbose_user <- FALSE}
  targetFromFormula <- strsplit(deparse(formula_class), " ")[[1]][1] # Extract the Target variable from the formula
  if (startsWith(targetFromFormula,"as.factor(")) { targetFromFormula <- regmatches(targetFromFormula, 
                                                                                    gregexpr( "(?<=\\().+?(?=\\))", 
                                                                                              targetFromFormula, 
                                                                                              perl = T))[[1]]}
  # target for softmax requires a factor target
  aux.formula <- unlist(strsplit(deparse(formula_class), " "))
  aux.formula[1] <- paste0("as.factor(",targetFromFormula,")")
  formula_softmax <- as.formula(paste(aux.formula,collapse=" "))
  
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('OML4Spark GLM2...')
  timing_glm2 <- list()
  start.time <- Sys.time()
  model_glm2 <- orch.glm2(formula = formula_class, data = INPUT_DATA, verbose=verbose_user)  
  build_timing <- Sys.time()-start.time
  timing_glm2[[1]] <- as.numeric(build_timing,units = "secs")
  timing_glm2[[2]] <- format(build_timing,digits=4)
  start.time <- Sys.time()
  pred_glm2  <- predict(model_glm2, newdata = TEST_DATA, supplemental = targetFromFormula, type='response', verbose=verbose_user)
  score_timing <- Sys.time()-start.time
  timing_glm2[[3]] <- as.numeric(score_timing,units = "secs")
  timing_glm2[[4]] <- format(score_timing,digits=4)
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_glm2[[1]]+timing_glm2[[3]] ,'secs \n')
  
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('OML4Spark Neural with Entropy Output Activation...')
  timing_neu_ent <- list()
  start.time <- Sys.time()
  model_neu_ent <- orch.neural2(formula = formula_class, data = INPUT_DATA, 
                                hiddenSizes    = c(20, 20),
                                activations    = c("sigmoid", "sigmoid", "entropy"),
                                seed           = 0, verbose=verbose_user)
  build_timing <- Sys.time()-start.time
  timing_neu_ent[[1]] <- as.numeric(build_timing,units = "secs")
  timing_neu_ent[[2]] <- format(build_timing,digits=4)
  start.time <- Sys.time()
  pred_neu_ent  <- predict(model_neu_ent, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
  score_timing <- Sys.time()-start.time
  timing_neu_ent[[3]] <- as.numeric(score_timing,units = "secs")
  timing_neu_ent[[4]] <- format(score_timing,digits=4)
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_neu_ent[[1]]+timing_neu_ent[[3]] ,'secs \n')
  
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('OML4Spark Neural with SoftMax Output Activation...')
  timing_neu_sof <- list()
  start.time <- Sys.time()
  model_neu_sof <- orch.neural2(formula = formula_softmax, data = INPUT_DATA, 
                                hiddenSizes    = c(20, 20),
                                activations    = c("sigmoid", "sigmoid", "softmax"),
                                seed           = 0, verbose=verbose_user)
  build_timing <- Sys.time()-start.time
  timing_neu_sof[[1]] <- as.numeric(build_timing,units = "secs")
  timing_neu_sof[[2]] <- format(build_timing,digits=4)
  start.time <- Sys.time()
  pred_neu_sof  <- predict(model_neu_sof, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
  score_timing <- Sys.time()-start.time
  timing_neu_sof[[3]] <- as.numeric(score_timing,units = "secs")
  timing_neu_sof[[4]] <- format(score_timing,digits=4)
  if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_neu_sof[[1]]+timing_neu_sof[[3]] ,'secs \n')
  
  if (sum(grepl(':',formula_class,fixed=TRUE))==0) {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('OML4Spark ELM...')
    timing_elm <- list()
    start.time <- Sys.time()
    model_elm <- orch.elm(formula = formula_class, data = INPUT_DATA,zScoreX = TRUE, 
                          l = 10, lambda = 1e-12 , verbose=verbose_user)
    build_timing <- Sys.time()-start.time  
    timing_elm[[1]] <- as.numeric(build_timing,units = "secs")
    timing_elm[[2]] <- format(build_timing,digits=4)
    start.time <- Sys.time()
    pred_elm  <- predict(model_elm, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
    score_timing <- Sys.time()-start.time
    timing_elm[[3]] <- as.numeric(score_timing,units = "secs")
    timing_elm[[4]] <- format(score_timing,digits=4)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_elm[[1]]+timing_elm[[3]] ,'secs \n')
  } else {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('ELM Model skipped due to factor interactions in formula \n') 
  }
  
  if (sum(grepl(':',formula_class,fixed=TRUE))==0) {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('OML4Spark H-ELM...')
    timing_helm <- list()
    start.time <- Sys.time()
    model_helm <- orch.helm(formula = formula_class, data = INPUT_DATA,zScoreX = TRUE,
                            l = c(10L, 50L), lambdaAEnc = 1e-3, lambdaELM = 1e-9, verbose=verbose_user)
    build_timing <- Sys.time()-start.time
    timing_helm[[1]] <- as.numeric(build_timing,units = "secs")
    timing_helm[[2]] <- format(build_timing,digits=4)
    start.time <- Sys.time()
    pred_helm  <- predict(model_helm, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
    score_timing <- Sys.time()-start.time
    timing_helm[[3]] <- as.numeric(score_timing,units = "secs")
    timing_helm[[4]] <- format(score_timing,digits=4)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_helm[[1]]+timing_helm[[3]] ,'secs \n')
  } else {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('H-ELM Model skipped due to factor interactions in formula \n') 
  }
  
  if (sum(grepl(':',formula_class,fixed=TRUE))==0) {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib Logistic...')
    timing_logistic <- list()  
    start.time <- Sys.time()
    model_logistic <- orch.ml.logistic(formula = formula_class, data = INPUT_DATA, threshold = prop, verbose=verbose_user)
    build_timing <- Sys.time()-start.time
    timing_logistic[[1]] <- as.numeric(build_timing,units = "secs")
    timing_logistic[[2]] <- format(build_timing,digits=4)
    start.time <- Sys.time()
    pred_logistic <- predict(model_logistic, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
    score_timing <- Sys.time()-start.time
    timing_logistic[[3]] <- as.numeric(score_timing,units = "secs")
    timing_logistic[[4]] <- format(score_timing,digits=4)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_logistic[[1]]+timing_logistic[[3]] ,'secs \n')
  } else {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib Logistic Model skipped due to factor interactions in formula \n') 
  }
  
  
  if (sum(grepl(':',formula_class,fixed=TRUE))==0) {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib Decision Trees...')
    timing_dt <- list()
    start.time <- Sys.time()
    model_dt <- orch.ml.dt(formula = formula_class, data = INPUT_DATA, 
                           threshold = prop, type="classification", verbose=verbose_user)
    build_timing <- Sys.time()-start.time
    timing_dt[[1]] <- as.numeric(build_timing,units = "secs")
    timing_dt[[2]] <- format(build_timing,digits=4)
    start.time <- Sys.time()
    pred_dt <- predict(model_dt, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
    score_timing <- Sys.time()-start.time
    timing_dt[[3]] <- as.numeric(score_timing,units = "secs")
    timing_dt[[4]] <- format(score_timing,digits=4)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_dt[[1]]+timing_dt[[3]] ,'secs \n')
  } else {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib Decision Trees Model skipped due to factor interactions in formula \n') 
  }
  
  if (sum(grepl(':',formula_class,fixed=TRUE))==0) {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib Random Forest...')
    timing_rf <- list()
    start.time <- Sys.time()
    model_rf <- orch.ml.random.forest(formula = formula_class, data = INPUT_DATA, nTrees = 100, 
                                      threshold = prop, type="classification", verbose=verbose_user)
    build_timing <- Sys.time()-start.time
    timing_rf[[1]] <- as.numeric(build_timing,units = "secs")
    timing_rf[[2]] <- format(build_timing,digits=4)
    start.time <- Sys.time()
    pred_rf <- predict(model_rf, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
    score_timing <- Sys.time()-start.time
    timing_rf[[3]] <- as.numeric(score_timing,units = "secs")
    timing_rf[[4]] <- format(score_timing,digits=4)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_rf[[1]]+timing_rf[[3]] ,'secs \n')
  } else {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib Random Forest Model skipped due to factor interactions in formula \n') 
  }
  
  if (sum(grepl(':',formula_class,fixed=TRUE))==0) {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib SVM...')
    timing_svm <- list()
    start.time <- Sys.time()
    model_svm <- orch.ml.svm(formula = formula_class, data = INPUT_DATA, threshold = prop, verbose=verbose_user)
    build_timing <- Sys.time()-start.time
    timing_svm[[1]] <- as.numeric(build_timing,units = "secs")
    timing_svm[[2]] <- format(build_timing,digits=4)
    start.time <- Sys.time()
    pred_svm <- predict(model_svm, newdata = TEST_DATA, supplemental = targetFromFormula, verbose=verbose_user)
    score_timing <- Sys.time()-start.time
    timing_svm[[3]] <- as.numeric(score_timing,units = "secs")
    timing_svm[[4]] <- format(score_timing,digits=4)
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('done in ',timing_svm[[1]]+timing_svm[[3]] ,'secs \n')
  } else {
    if (grepl(feedback, "FULL|TRUE", fixed = TRUE)) cat('Spark MLlib SVM Model skipped due to factor interactions in formula \n') 
  }
  
  # Returns a list with all Models and their 
  # Predictions Vector (which contains the Actual plus Predictions)
  out <- list()
  if (sum(grepl(':',formula_class,fixed=TRUE))==0) {
    out <- list(list(model_glm2,pred_glm2,paste0('OML4Spark GLM2',legend),timing_glm2),
                list(model_neu_ent,pred_neu_ent, paste0('OML4Spark Neural Nets - Entropy Activation',legend),timing_neu_ent),
                list(model_neu_sof,pred_neu_sof, paste0('OML4Spark Neural Nets - SoftMax Activation',legend),timing_neu_sof),
                list(model_elm,pred_elm, paste0('OML4Spark Extreme Learning Machines',legend),timing_elm),
                list(model_helm,pred_helm, paste0('OML4Spark Hybrid-Extreme Learning Machines',legend),timing_helm),
                list(model_logistic,pred_logistic, paste0('Spark MLlib Logistic',legend),timing_logistic),
                list(model_dt,pred_dt, paste0('Spark MLlib Decision Trees',legend),timing_dt),
                list(model_rf,pred_rf, paste0('Spark MLlib Random Forest',legend),timing_rf),
                list(model_svm,pred_svm, paste0('Spark MLlib Support Vector Machines',legend),timing_svm)
                #              ,
                #              list(model_lasso,pred_lasso, paste0('Spark MLlib LASSO',legend),timing_lasso)
    )
  } else {
    out <- list(list(model_glm2,pred_glm2,paste0('OML4Spark GLM2',legend),timing_glm2),
                list(model_neu_ent,pred_neu_ent, paste0('OML4Spark Neural Nets - Entropy Activation',legend),timing_neu_ent),
                list(model_neu_sof,pred_neu_sof, paste0('OML4Spark Neural Nets - SoftMax Activation',legend),timing_neu_sof))
  }
  
  return(out)
  
}  # END OF CLASSIFICATION MODELS
