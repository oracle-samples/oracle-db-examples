-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   OML R Extensible - Regression - Neural Networks Algorithm - dmrnndemo.sql
--   
--   Copyright (c) 2026 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------
SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
SET LONG 10000

-------------------------------------------------------------------------------
--                         NEURAL NETWORK REGRESSION DEMO
-------------------------------------------------------------------------------
-- Explaination:
-- This demo shows how to implement the neural network regression algorithm in 
-- Oracle Data Mining using R nnet algorithm.

-- Cleanup old output table for repeat runs -----------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE NN_RDEMO_SETTINGS_RE';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/

Begin
  sys.rqScriptDrop('NN_RDEMO_BUILD_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('NN_RDEMO_SCORE_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('NN_RDEMO_DETAILS_REGRESSION', v_silent => TRUE);
End;
/

-- Model Settings -------------------------------------------------------------
CREATE TABLE NN_RDEMO_SETTINGS_RE (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

BEGIN
 INSERT INTO NN_RDEMO_SETTINGS_RE VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
END;
/

Begin
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named NN_RDEMO_BUILD_REGRESSION is defined. This 
-- function builds and returns a neural network regression model using R nnet 
-- algorithm. User can also choose other R algorithm to implement the neural
-- network regression algorithm.

  sys.rqScriptCreate('NN_RDEMO_BUILD_REGRESSION', 'function(dat) {
   require(nnet); 
   set.seed(1234); 
   mod <- nnet(formula=AGE ~ ., data=dat, 
               size=0, skip=TRUE, linout=TRUE, trace=FALSE); mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named NN_RDEMO_SCORE_REGRESSION is defined. 
-- This function creates and returns an R data.frame containing the target 
-- predictions. User can also define other prediction functions with different 
-- settings.

  sys.rqScriptCreate('NN_RDEMO_SCORE_REGRESSION', 'function(mod, dat) {
   require(nnet); 
   res <- predict(mod, newdata = dat);
   data.frame(pred=res)}');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named NN_RDEMO_DETAILS_REGRESSION
-- is defined. This function creates and returns an R data.frame containing the 
-- weights of the built neural network regression model. User can also display 
-- other details.

  sys.rqScriptCreate('NN_RDEMO_DETAILS_REGRESSION', 'function(object, x) {
    mod <- object; 
    data.frame(wts=mod$wts)}');

  INSERT INTO NN_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_build_function, 'NN_RDEMO_BUILD_REGRESSION');
  INSERT INTO NN_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_score_function, 'NN_RDEMO_SCORE_REGRESSION');
  INSERT INTO NN_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_details_function, 'NN_RDEMO_DETAILS_REGRESSION');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- weights of the built neural network regression model.

  INSERT INTO NN_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_details_format, 'select 1 wts from dual');
End;
/

BEGIN DBMS_DATA_MINING.DROP_MODEL('NN_RDEMO_REGRESSION');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------
-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- NN_RDEMO_BUILD_REGRESSION will be used to create the neural network 
-- regression model NN_RDEMO_REGRESSION using dataset mining_data_build_v.

BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'NN_RDEMO_REGRESSION',
    mining_function     => dbms_data_mining.regression,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'AGE',
    settings_table_name => 'NN_RDEMO_SETTINGS_RE');
END;
/

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------
-- Explanation:
-- Display the details of the built model using the R script user defined. 
-- Here R script NN_RDEMO_DETAIL_REGRESSION will be used to display the model 
-- details.

select round(wts, 3) as wts from DM$VDNN_RDEMO_REGRESSION where wts >= 4 
order by wts;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------
-- Explanation:
-- Score the model using the R script user defined. Here R script 
-- NN_RDEMO_SCORE_REGRESSION will be used to do the scoring. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Show actual target value and predicted target values.

SELECT CUST_ID, AGE as AGE_act, 
round(PREDICTION(NN_RDEMO_REGRESSION USING *), 3) as AGE_pred
FROM mining_data_apply_v where CUST_ID <= 100010 
order by CUST_ID;

-------------------------------------------------------------------------------
--                        NEURAL NETWORK CLASSIFICATION DEMO
-------------------------------------------------------------------------------
-- Explaination:
-- This demo shows how to implement the neural network classification algorithm
-- in Oracle Data Mining using R nnet algorithm.

-- Cleanup old output table for repeat runs -----------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE NN_RDEMO_SETTINGS_CL';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/

Begin
  sys.rqScriptDrop('NN_RDEMO_BUILD_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('NN_RDEMO_SCORE_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('NN_RDEMO_DETAILS_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('NN_RDEMO_WEIGHT_CLASSIFICATION', v_silent => TRUE);
End;
/

-- Model Settings -------------------------------------------------------------
CREATE TABLE NN_RDEMO_SETTINGS_CL (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

BEGIN
 INSERT INTO NN_RDEMO_SETTINGS_CL VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
END;
/

Begin
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named NN_RDEMO_BUILD_CLASSIFICATION is defined. 
-- This function builds and returns a neural network classification model using 
-- R nnet algorithm. User can also choose other R algorithm to implement the
-- neural network classification algorithm.

  sys.rqScriptCreate('NN_RDEMO_BUILD_CLASSIFICATION', 'function(dat) {
   require(nnet); 
   set.seed(1234); 
   mod <- nnet(formula=HOUSEHOLD_SIZE ~ ., data=dat, 
               size=0, skip=TRUE, linout=TRUE, trace=FALSE); 
   mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named NN_RDEMO_SCORE_CLASSIFICATION is 
-- defined. This function creates and returns an R data.frame containing the 
-- target predictions. User can also define other prediction functions with 
-- different types.

  sys.rqScriptCreate('NN_RDEMO_SCORE_CLASSIFICATION', 'function(mod, dat) {
   require(nnet); 
   res <- predict(mod, newdata = dat); 
   res=data.frame(res);
   names(res) <- sort(mod$lev); res}');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named 
-- NN_RDEMO_DETAILS_CLASSIFICATION is defined. This function creates and 
-- returns an R data.frame containing the weights of the built neural network 
-- classification model. User can also display other details.

  sys.rqScriptCreate('NN_RDEMO_DETAILS_CLASSIFICATION', 'function(object, x) {
   mod <- object; 
   data.frame(wts=mod$wts)}');

-- Weight R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to provide the attribute weights
-- of the scoring data. For example, here a script named 
-- NN_RDEMO_WEIGHT_CLASSIFICATION is defined. This function creates and returns
-- an R data.frame containing the weights of each attribute of the scoring data.
-- Here we simply use the ratio of the predicted target probability with all
-- attribute values present to the predicted target probability with one 
-- attribute value missing as the weight of the missing attribute. User can 
-- define their own method to calculate the attribute weight.

  sys.rqScriptCreate('NN_RDEMO_WEIGHT_CLASSIFICATION', 'function(mod, dat, clas) {
   require(nnet);
   Sys.setlocale(, "C");
   v0 <- as.data.frame(predict(mod, newdata=dat, type = "raw"));
   res <- data.frame(lapply(seq_along(dat),
   function(x, dat) {
   if(is.numeric(dat[[x]])) dat[,x] <- as.numeric(0)
   else dat[,x] <- mod$xlevels[[names(dat[x])]][1];
   vv <- as.data.frame(predict(mod, newdata = dat, type = "raw"));
   max((v0[[clas]]-vv[[clas]])/v0[[clas]], 0)}, dat = dat));
   res <- res[,order(names(dat))];
   names(res) <- sort(names(dat)); 
   res}');

  INSERT INTO NN_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_build_function, 'NN_RDEMO_BUILD_CLASSIFICATION');
  INSERT INTO NN_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_score_function, 'NN_RDEMO_SCORE_CLASSIFICATION');
  INSERT INTO NN_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_details_function, 'NN_RDEMO_DETAILS_CLASSIFICATION');
  INSERT INTO NN_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_weight_function, 'NN_RDEMO_WEIGHT_CLASSIFICATION');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- weights of the built neural network classification model.

  INSERT INTO NN_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_details_format, 'select 1 wts from dual');
End;
/

BEGIN DBMS_DATA_MINING.DROP_MODEL('NN_RDEMO_CLASSIFICATION');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------
-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- NN_RDEMO_BUILD_CLASSIFICATION will be used to create the neural network 
-- classification model NN_RDEMO_CLASSIFICATION using dataset mining_data_build_v.

BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'NN_RDEMO_CLASSIFICATION',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'HOUSEHOLD_SIZE',
    settings_table_name => 'NN_RDEMO_SETTINGS_CL');
END;
/

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------
-- Display the details of the built model using the R script user defined. 
-- Here R script NN_RDEMO_DETAIL_CLASSIFICATION will be used to display the 
-- model details.

select round(wts, 3) as wts from DM$VDNN_RDEMO_CLASSIFICATION where wts >= 10 
order by wts;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------
-- Explanation:
-- Score the model using the R script user defined. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Here R script NN_RDEMO_SCORE_CLASSIFICATION is used to get the prediction 
-- value and the prediction probability. Actual target value and predicted 
-- target values are provided.

SELECT CUST_ID, HOUSEHOLD_SIZE as HOUSEHOLD_SIZE_act, 
PREDICTION(NN_RDEMO_CLASSIFICATION USING *) HOUSEHOLD_SIZE_pred,
round(PREDICTION_PROBABILITY(NN_RDEMO_CLASSIFICATION USING *), 3) 
as HOUSEHOLD_SIZE_prob 
FROM mining_data_apply_v where CUST_ID <= 100010 
order by CUST_ID;

-- PREDICTION_SET -------------------------------------------------------------
-- Explanation:
-- Here R script NN_RDEMO_SCORE_CLASSIFICATION is used to get the 
-- prediction set. Actual target value and predicted target values are provided. 

select T.CUST_ID, T.HOUSEHOLD_SIZE, S.prediction, 
round(S.probability, 3) as probability 
from (select CUST_ID, HOUSEHOLD_SIZE, 
PREDICTION_SET(NN_RDEMO_CLASSIFICATION USING *) pset 
from mining_data_apply_v where CUST_ID <= 100005) T, TABLE(T.pset) S
where S.probability > 0 
order by T.CUST_ID, S.prediction;

-- PREDICTION_DETAILS ---------------------------------------------------------
-- Explanation:
-- The R script NN_RDEMO_WEIGHT_CLASSIFICATION is used to get the prediction 
-- details. The HOUSEHOLD_SIZE and the prediction details with the weight of each 
-- attribute are provided.

column pred_det format a60;
SELECT CUST_ID, 
PREDICTION_DETAILS(NN_RDEMO_CLASSIFICATION, '2' USING *) pred_det
FROM mining_data_apply_v where CUST_ID <= 100010 order by CUST_ID;
