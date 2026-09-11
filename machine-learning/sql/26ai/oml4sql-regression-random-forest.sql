-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   Regression - Random Forest Algorithm - dmrrfdemo.sql  
--   Copyright (c) 2026 Oracle Corporation and/or its affiliates.
--
--   The Universal Permissive License (UPL), Version 1.0
--   https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
SET LONG 10000

-------------------------------------------------------------------------------
--                         RANDOMFOREST REGRESSION DEMO
-------------------------------------------------------------------------------

-- Explaination:
-- This demo shows how to implement the random forest regression algorithm in 
-- Oracle Data Mining using R nnet algorithm.

-- Cleanup old output table for repeat runs -----------------------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE RF_RDEMO_SETTINGS_RE';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  sys.rqScriptDrop('RF_RDEMO_BUILD_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('RF_RDEMO_SCORE_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('RF_RDEMO_DETAILS_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('RF_RDEMO_WEIGHT_REGRESSION', v_silent => TRUE);
END;
/

-- Model Settings -------------------------------------------------------------


BEGIN
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named RF_RDEMO_BUILD_REGRESSION is defined. This 
-- function builds and returns a random forest regression model using R
-- randomForest algorithm. User can also choose other R algorithm to implement 
-- the random forest regression algorithm.

  sys.rqScriptCreate('RF_RDEMO_BUILD_REGRESSION', 'function(dat, form) {
   require(randomForest); 
   set.seed(1234); 
   mod <- randomForest(formula = formula(form), data=dat); 
   mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named RF_RDEMO_SCORE_REGRESSION is defined. 
-- This function creates and returns an R data.frame containing the target 
-- predictions. User can also define other PREDICTION functions with different 
-- settings. Note that the randomForest function in R requires types and levels 
-- of the scoring data be exactly same with types and levels of training data

  sys.rqScriptCreate('RF_RDEMO_SCORE_REGRESSION', 'function(mod, dat) {
   require(randomForest);

   for(i in 1:length(names(dat))) {
       if(is.numeric(dat[1,i])) {
         dat[,i] = as.numeric(dat[,i]);} 
       else {
         dat[,i] = factor(dat[,i], levels=mod$forest$xlevels[[i]]);
       } 
   }

   res <- predict(mod, newdata = dat);
   data.frame(pred=res)}');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named RF_RDEMO_DETAILS_REGRESSION
-- is defined. This function creates and returns an R data.frame containing the 
-- attribute importance of the built random forest regression model. User can 
-- also display other details.

  sys.rqScriptCreate('RF_RDEMO_DETAILS_REGRESSION', 'function(object, x) {
   mod <- object;
   data.frame(row_name=row.names(mod$importance), importance=mod$importance)}');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding importance.

-- In this setting, a formula is specified, which will be passed as a parameter 
-- to the model build function to build the model.

END;
/


-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------

-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- RF_RDEMO_BUILD_REGRESSION will be used to create the random forest 
-- regression model RF_RDEMO_REGRESSION using dataset mining_data_build_v.


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RF_RDEMO_REGRESSION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'RF_RDEMO_BUILD_REGRESSION';
  v_setlst(dbms_data_mining.ralg_score_function) := 'RF_RDEMO_SCORE_REGRESSION';
  v_setlst(dbms_data_mining.ralg_details_function) := 'RF_RDEMO_DETAILS_REGRESSION';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(100)) name, 1 importance FROM dual';
  v_setlst(dbms_data_mining.ralg_build_parameter) := 'SELECT ''AGE ~ .'' "form" FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'RF_RDEMO_REGRESSION',
    mining_function     => dbms_data_mining.regression,
    data_query          => 'SELECT * FROM mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'AGE',
    set_list            => v_setlst
    );
END;
/

-----------------------------------------------------------------------
-- CREATE_MODEL EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL is useful for application development when model settings
-- are separated into a settings table for convenient updating.
-- This build intentionally replaces the model created by the preceding CREATE_MODEL2 example.

-- Drop settings table if it exists
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE RF_RDEMO_SETTINGS_RE';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RF_RDEMO_REGRESSION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE RF_RDEMO_SETTINGS_RE (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO RF_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO RF_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'RF_RDEMO_BUILD_REGRESSION');
    INSERT INTO RF_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'RF_RDEMO_SCORE_REGRESSION');
    INSERT INTO RF_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'RF_RDEMO_DETAILS_REGRESSION');
    INSERT INTO RF_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(100)) name, 1 importance FROM dual');
    INSERT INTO RF_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_parameter, 'SELECT ''AGE ~ .'' "form" FROM dual');
END;
/
BEGIN
  dbms_data_mining.create_model(
      model_name          => 'RF_RDEMO_REGRESSION',
      mining_function     => dbms_data_mining.regression,
      data_table_name     => 'mining_data_build_v',
      case_id_column_name => 'CUST_ID',
      target_column_name  => 'AGE',
      settings_table_name => 'RF_RDEMO_SETTINGS_RE');
END;
/

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------

-- Explanation:
-- Display the details of the built model using the R script user defined. 
-- Here R script RF_RDEMO_DETAIL_REGRESSION will be used to display the model 
-- details.

column name format a30;

SELECT name, round(importance, 3) as importance, 
rank() OVER (ORDER BY importance DESC) rank 
FROM DM$VDRF_RDEMO_REGRESSION ORDER BY importance DESC;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------

-- Explanation:
-- Score the model using the R script user defined. Here R script 
-- RF_RDEMO_SCORE_REGRESSION will be used to do the scoring. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Show actual target value and predicted target values.

SELECT CUST_ID, AGE as AGE_act, 
round(PREDICTION(RF_RDEMO_REGRESSION USING *), 3) as AGE_pred 
FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY CUST_ID;

-------------------------------------------------------------------------------
--                        RANDOM FOREST CLASSIFICATION DEMO
-------------------------------------------------------------------------------

-- Explaination:
-- This demo shows how to implement the random forest classification algorithm
-- in Oracle Data Mining using R randomForest algorithm.

-- Cleanup old output table for repeat runs -----------------------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE RF_RDEMO_SETTINGS_CL';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  sys.rqScriptDrop('RF_RDEMO_BUILD_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('RF_RDEMO_SCORE_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('RF_RDEMO_DETAILS_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('RF_RDEMO_WEIGHT_CLASSIFICATION', v_silent => TRUE);
END;
/

-- Model Settings -------------------------------------------------------------


BEGIN
-- Build Function -------------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named RF_RDEMO_BUILD_CLASSIFICATION is defined. 
-- This function builds and returns a random forest classification model using 
-- R randomForest algorithm. User can also choose other R algorithm to 
-- implement the random forest classification algorithm.

  sys.rqScriptCreate('RF_RDEMO_BUILD_CLASSIFICATION', 'function(dat) {
   require(randomForest); 
   set.seed(1234); 
   dat$AFFINITY_CARD=as.factor(dat$AFFINITY_CARD); 
   mod <- randomForest(AFFINITY_CARD ~ ., data=dat); 
   mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named RF_RDEMO_SCORE_CLASSIFICATION is 
-- defined. This function creates and returns an R data.frame containing the 
-- target predictions with type vote. User can also define other PREDICTION 
-- functions with other types. Note that the randomForest function in R 
-- requires types and levels of the scoring data be exactly same with types 
-- and levels of training data

  sys.rqScriptCreate('RF_RDEMO_SCORE_CLASSIFICATION', 'function(mod, dat) {
  require(randomForest); 

  for(i in 1:length(names(dat))) {
      if(is.numeric(dat[1,i])) {
        dat[,i] = as.numeric(dat[,i]);} 
      else {
        dat[,i] = factor(dat[,i], levels=mod$forest$xlevels[[i]]);
      }  
  }

  res <- data.frame(predict(mod, newdata=dat, type="vote"));
  names(res) <- c("0", "1");
  res}');
  
-- Detail R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named 
-- RF_RDEMO_DETAILS_CLASSIFICATION is defined. This function creates and 
-- returns an R data.frame containing the attribute importance of the built
-- random forest classification model. User can also display other details.

  sys.rqScriptCreate('RF_RDEMO_DETAILS_CLASSIFICATION', 'function(object, x) {
   mod <- object; 
   data.frame(row_name=row.names(mod$importance), importance=mod$importance)}');

-- Weight R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to provide the attribute weights
-- of the scoring data. For example, here a script named 
-- RF_RDEMO_WEIGHT_CLASSIFICATION is defined. This function creates and returns
-- an R data.frame containing the weights of each attribute of the scoring data.
-- Here we simply use the ratio of the predicted target probability with all
-- attribute values present to the predicted target probability with one 
-- attribute value missing as the weight of the missing attribute. User can 
-- define their own method to calculate the attribute weight. Note that the 
-- randomForest function in R requires types and levels of the scoring data be 
-- exactly same with types and levels of training data.

  sys.rqScriptCreate('RF_RDEMO_WEIGHT_CLASSIFICATION', 'function(mod, dat, clas) {
   require(randomForest); 

   for(i in 1:length(names(dat))) {
       if(is.numeric(dat[,i])) {
         dat[,i] = as.numeric(dat[,i]);} 
       else {
         dat[,i] = factor(dat[,i], levels=mod$forest$xlevels[[i]]);
       }  
   }

   v0 <- as.data.frame(predict(mod, newdata=dat, type = "prob"));
   res <- data.frame(lapply(seq_along(dat),
   function(x, dat) {
   if(is.numeric(dat[[x]])) dat[,x] <- as.numeric(0)
   else {dat[,x] <- factor(NA, levels = mod$forest$xlevels[[x]]);};
   vv <- as.data.frame(predict(mod, newdata = dat, type = "prob"));
   v0[[clas]] / vv[[clas]]}, dat = dat));
   names(res) <- names(dat);
   res}');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding importance.

END;
/


-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------

-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- RF_RDEMO_BUILD_CLASSIFICATION will be used to create the random forest 
-- classification model RF_RDEMO_CLASSIFICATION using dataset mining_data_build_v.


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RF_RDEMO_CLASSIFICATION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'RF_RDEMO_BUILD_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_score_function) := 'RF_RDEMO_SCORE_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_details_function) := 'RF_RDEMO_DETAILS_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_weight_function) := 'RF_RDEMO_WEIGHT_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(100)) name, 1 importance FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'RF_RDEMO_CLASSIFICATION',
    mining_function     => dbms_data_mining.classification,
    data_query          => 'SELECT * FROM mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'AFFINITY_CARD',
    set_list            => v_setlst
    );
END;
/

-----------------------------------------------------------------------
-- CREATE_MODEL EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL is useful for application development when model settings
-- are separated into a settings table for convenient updating.
-- This build intentionally replaces the model created by the preceding CREATE_MODEL2 example.

-- Drop settings table if it exists
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE RF_RDEMO_SETTINGS_CL';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RF_RDEMO_CLASSIFICATION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE RF_RDEMO_SETTINGS_CL (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO RF_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO RF_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'RF_RDEMO_BUILD_CLASSIFICATION');
    INSERT INTO RF_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'RF_RDEMO_SCORE_CLASSIFICATION');
    INSERT INTO RF_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'RF_RDEMO_DETAILS_CLASSIFICATION');
    INSERT INTO RF_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_weight_function, 'RF_RDEMO_WEIGHT_CLASSIFICATION');
    INSERT INTO RF_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(100)) name, 1 importance FROM dual');
END;
/
BEGIN
  dbms_data_mining.create_model(
      model_name          => 'RF_RDEMO_CLASSIFICATION',
      mining_function     => dbms_data_mining.classification,
      data_table_name     => 'mining_data_build_v',
      case_id_column_name => 'CUST_ID',
      target_column_name  => 'AFFINITY_CARD',
      settings_table_name => 'RF_RDEMO_SETTINGS_CL');
END;
/

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------

-- Display the details of the built model using the R script user defined. 
-- Here R script RF_RDEMO_DETAIL_CLASSIFICATION will be used to display the 
-- model details.

column name format a30;

SELECT name, round(importance, 3) as importance, 
rank() OVER (ORDER BY importance DESC) rank 
FROM DM$VDRF_RDEMO_CLASSIFICATION ORDER BY importance DESC;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------

-- Explanation:
-- Score the model using the R script user defined. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Here R script RF_RDEMO_SCORE_CLASSIFICATION is used to get the PREDICTION 
-- value and the PREDICTION probability. Actual target value and predicted 
-- target values are provided.

SELECT cust_id, affinity_card as affinity_card_act, 
PREDICTION(RF_RDEMO_CLASSIFICATION USING *) affinity_card_pred,
round(PREDICTION_PROBABILITY(RF_RDEMO_CLASSIFICATION USING *), 3) 
as affinity_card_prob 
FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY cust_id;

-- PREDICTION_SET -------------------------------------------------------------
-- Explanation:
-- Here R script RF_RDEMO_SCORE_CLASSIFICATION is used to get the 
-- PREDICTION set. Actual target value and predicted target values are provided.

SELECT T.CUST_ID, T.affinity_card, S.PREDICTION, 
round(S.probability, 3) as probability  
FROM (SELECT CUST_ID, affinity_card, 
PREDICTION_SET(RF_RDEMO_CLASSIFICATION USING *) pset 
FROM mining_data_apply_v WHERE CUST_ID <= 100010) T, TABLE(T.pset) S
WHERE S.probability > 0 
ORDER BY T.CUST_ID, S.PREDICTION;

-- PREDICTION_DETAILS ---------------------------------------------------------
-- Explanation:
-- The R script RF_RDEMO_WEIGHT_CLASSIFICATION is used to get the PREDICTION 
-- details. The AFFINITY_CARD and PREDICTION details with each attribute weight
-- are provided.

column pred_det format a65;

SELECT CUST_ID, PREDICTION_DETAILS(RF_RDEMO_CLASSIFICATION, '1' USING *) pred_det
FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY CUST_ID;

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('RF_RDEMO_REGRESSION');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('RF_RDEMO_CLASSIFICATION');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE RF_RDEMO_SETTINGS_RE';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE RF_RDEMO_SETTINGS_CL';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
