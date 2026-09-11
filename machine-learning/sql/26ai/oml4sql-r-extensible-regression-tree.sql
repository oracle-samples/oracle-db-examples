-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   OML R Extensible - Regression Tree Algorithm - dmrdtdemo.sql  
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
--                         REGRESSION TREE DEMO
-------------------------------------------------------------------------------

-- Explaination:
-- This demo shows how to implement the regression tree algorithm in Oracle Data 
-- Mining using R rpart algorithm

-- Cleanup old output tables/scripts/models for repeat runs -------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE DT_RDEMO_SETTINGS_RE';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
 sys.rqScriptDrop('DT_RDEMO_BUILD_REGRESSION', v_silent => TRUE);
 sys.rqScriptDrop('DT_RDEMO_SCORE_REGRESSION', v_silent => TRUE);
 sys.rqScriptDrop('DT_RDEMO_DETAILS_REGRESSION', v_silent => TRUE);
 sys.rqScriptDrop('DT_RDEMO_WEIGHT_REGRESSION', v_silent => TRUE);
END;
/


-- Model Settings -------------------------------------------------------------


BEGIN
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named DT_RDEMO_BUILD_REGRESSION is defined. This 
-- function builds and returns a regression tree model using R rpart algorithm. 
-- User can also choose other R algorithm to implement the regression tree 
-- algorithm.

  sys.rqScriptCreate('DT_RDEMO_BUILD_REGRESSION', 'function(dat) {
   require(rpart); 
   set.seed(1234); 
   mod <- rpart(AGE ~ ., data=dat, method="anova"); 
   mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named DT_RDEMO_SCORE_REGRESSION is defined. 
-- This function creates and returns an R data.frame containing the target 
-- predictions using vector type. User can also define other PREDICTION function
-- with different types.

  sys.rqScriptCreate('DT_RDEMO_SCORE_REGRESSION', 'function(mod, dat) {
   require(rpart); 
   res <- predict(mod, newdata=dat, type = "vector"); 
   data.frame(res)}');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named DT_RDEMO_DETAILS_REGRESSION
-- is defined. This function creates and returns an R data.frame containing the 
-- split attributes, node counts, weights, deviation and mean of the built model. 
-- User can also display other details.

  sys.rqScriptCreate('DT_RDEMO_DETAILS_REGRESSION', 'function(object, x) {
   mod.frm <- object$frame
   data.frame(node = row.names(mod.frm), split = mod.frm$var, n = mod.frm$n,
   wt = mod.frm$wt, dev = mod.frm$dev, yval = mod.frm$yval)}');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- split attributes, node counts, weights, deviation and mean of the built model

 
END;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------

-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- DT_RDEMO_BUILD_REGRESSION will be used to create the regression tree model 
-- DT_RDEMO_REGRESSION using dataset mining_data_build_v.


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('DT_RDEMO_REGRESSION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'DT_RDEMO_BUILD_REGRESSION';
  v_setlst(dbms_data_mining.ralg_score_function) := 'DT_RDEMO_SCORE_REGRESSION';
  v_setlst(dbms_data_mining.ralg_details_function) := 'DT_RDEMO_DETAILS_REGRESSION';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(20)) node, ' ||
   'cast(''a'' as varchar2(20)) split, ' ||
   '1 NodeCnt, 1 wt, 1 deviation, 1 mean FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'DT_RDEMO_REGRESSION',
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
  EXECUTE IMMEDIATE 'DROP TABLE DT_RDEMO_SETTINGS_RE';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('DT_RDEMO_REGRESSION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE DT_RDEMO_SETTINGS_RE (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO DT_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO DT_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'DT_RDEMO_BUILD_REGRESSION');
    INSERT INTO DT_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'DT_RDEMO_SCORE_REGRESSION');
    INSERT INTO DT_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'DT_RDEMO_DETAILS_REGRESSION');
    INSERT INTO DT_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(20)) node, ' ||
     'cast(''a'' as varchar2(20)) split, ' ||
     '1 NodeCnt, 1 wt, 1 deviation, 1 mean FROM dual');
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'DT_RDEMO_REGRESSION',
      mining_function     => dbms_data_mining.regression,
      data_table_name     => 'mining_data_build_v',
      case_id_column_name => 'CUST_ID',
      target_column_name  => 'AGE',
      settings_table_name => 'DT_RDEMO_SETTINGS_RE');
END;
/

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------

-- Display the details of the built model using the R script user defined. 
-- Here R script DT_RDEMO_DETAIL_REGRESSION will be used to display the model 
-- details.

column SPLIT format a12;

SELECT to_number(node) as node, split, NodeCnt, wt, 
round(deviation, 3) as deviation, round(mean, 3) as mean 
FROM DM$VDDT_RDEMO_REGRESSION 
ORDER BY node, split;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------

-- Explanation:
-- Score the model using the R script user defined. Here R script 
-- DT_RDEMO_SCORE_REGRESSION will be used to do the scoring. Actual target value
-- and predicted target values are provided. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
SELECT CUST_ID, AGE as AGE_act, round(PREDICTION(DT_RDEMO_REGRESSION USING *),3)
 AGE_pred FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY CUST_ID;

-------------------------------------------------------------------------------
--                        CLASSIFICATION TREE DEMO
-------------------------------------------------------------------------------

-- Explaination:
-- This demo shows how to implement the classification tree algorithm in Oracle 
-- Data Mining using R rpart algorithm

-- Cleanup old output tables/scripts/models for repeat runs -------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE DT_RDEMO_SETTINGS_CL';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

Begin
  sys.rqScriptDrop('DT_RDEMO_BUILD_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('DT_RDEMO_SCORE_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('DT_RDEMO_DETAILS_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('DT_RDEMO_WEIGHT_CLASSIFICATION', v_silent => TRUE);
End;
/


-- Model Settings -------------------------------------------------------------


BEGIN
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named DT_RDEMO_BUILD_CLASSIFICATION is defined. 
-- This function builds and returns a classification tree model using R rpart 
-- algorithm. User can also choose other R algorithm to implement the 
-- classification tree algorithm.

  sys.rqScriptCreate('DT_RDEMO_BUILD_CLASSIFICATION', 'function(dat) {
   require(rpart); 
   set.seed(1234); 
   mod <- rpart(AFFINITY_CARD ~ ., method="class", data=dat); 
   mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named DT_RDEMO_SCORE_CLASSIFICATION is 
-- defined. This function creates and returns an R data.frame containing the 
-- target predictions using prob type. User can also define other PREDICTION 
-- function with different types.

  sys.rqScriptCreate('DT_RDEMO_SCORE_CLASSIFICATION', 'function(mod, dat) {
   require(rpart);
   res <- data.frame(predict(mod, newdata=dat, type = "prob"));
   names(res) <- c("0", "1");
   res}');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named 
-- DT_RDEMO_DETAILS_CLASSIFICATION is defined. This function creates and 
-- returns an R data.frame containing the split attributes, node counts, left 
-- node counts, right node counts of the built model. User can also display 
-- other details.

  sys.rqScriptCreate('DT_RDEMO_DETAILS_CLASSIFICATION', 'function(object, x) {
   mod.frm <- object$frame
   data.frame(node = row.names(mod.frm), split = mod.frm$var, n = mod.frm$n,
   ln = mod.frm$yval2[,2], rn = mod.frm$yval2[,3])}');

-- Weight R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to provide attribute relative 
-- contribution to the PREDICTION. For example, here a script named 
-- DT_RDEMO_WEIGHT_CLASSIFICATION is defined. This function creates and returns
-- an R data.frame containing the contribution weight of each attribute to the 
-- PREDICTION probability of the specified class. Here we simply use the ratio 
-- of the predicted target probability with all attribute values present to the 
-- predicted target probability with one attribute value missing as the weight 
-- of the missing attribute for the specified class. User can define their own 
-- method to calculate the attribute weight.

  sys.rqScriptCreate('DT_RDEMO_WEIGHT_CLASSIFICATION', 'function(mod, dat, clas) {
   require(rpart); 

   v0 <- as.data.frame(predict(mod, newdata=dat, type = "prob"));
   res <- data.frame(lapply(seq_along(dat),
   function(x, dat) {
   if(is.numeric(dat[[x]])) dat[,x] <- as.numeric(NA)
   else dat[,x] <- as.factor(NA);
   vv <- as.data.frame(predict(mod, newdata = dat, type = "prob"));
   v0[[clas]] / vv[[clas]]}, dat = dat));
   names(res) <- names(dat);
   res}');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- split attributes, node counts, left node counts, right node counts of 
-- the built model

END;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------

-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- DT_RDEMO_BUILD_CLASSIFICATION will be used to create the classification tree 
-- model DT_RDEMO_CLASSIFICATION using dataset mining_data_build_v.


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('DT_RDEMO_CLASSIFICATION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'DT_RDEMO_BUILD_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_score_function) := 'DT_RDEMO_SCORE_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_details_function) := 'DT_RDEMO_DETAILS_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_weight_function) := 'DT_RDEMO_WEIGHT_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(20)) node, ' ||
    'cast(''a'' as varchar2(20)) split, ' ||
    '1 NodeCnt, 1 LeftNodeCnt, 1 RightNodeCnt FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'DT_RDEMO_CLASSIFICATION',
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
  EXECUTE IMMEDIATE 'DROP TABLE DT_RDEMO_SETTINGS_CL';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('DT_RDEMO_CLASSIFICATION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE DT_RDEMO_SETTINGS_CL (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO DT_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO DT_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'DT_RDEMO_BUILD_CLASSIFICATION');
    INSERT INTO DT_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'DT_RDEMO_SCORE_CLASSIFICATION');
    INSERT INTO DT_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'DT_RDEMO_DETAILS_CLASSIFICATION');
    INSERT INTO DT_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_weight_function, 'DT_RDEMO_WEIGHT_CLASSIFICATION');
    INSERT INTO DT_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(20)) node, ' ||
      'cast(''a'' as varchar2(20)) split, ' ||
      '1 NodeCnt, 1 LeftNodeCnt, 1 RightNodeCnt FROM dual');
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'DT_RDEMO_CLASSIFICATION',
      mining_function     => dbms_data_mining.classification,
      data_table_name     => 'mining_data_build_v',
      case_id_column_name => 'CUST_ID',
      target_column_name  => 'AFFINITY_CARD',
      settings_table_name => 'DT_RDEMO_SETTINGS_CL');
END;
/

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------

-- Display the details of the built model using the R script user defined. 
-- Here R script DT_RDEMO_DETAIL_CLASSIFICATION will be used to display the model 
-- details.

column SPLIT format a12;

SELECT to_number(node) as node, split, nodecnt, leftnodecnt, rightnodecnt 
FROM DM$VDDT_RDEMO_CLASSIFICATION
ORDER BY node, split;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------

-- Explanation:
-- Score the model using the R script user defined. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Here R script DT_RDEMO_SCORE_CLASSIFICATION is used to get the PREDICTION 
-- value and the PREDICTION probability. Actual target value and predicted 
-- target values are provided. 

SELECT cust_id, affinity_card as affinity_card_act, 
PREDICTION(DT_RDEMO_CLASSIFICATION USING *) affinity_card_pred,
round(PREDICTION_PROBABILITY(DT_RDEMO_CLASSIFICATION USING *), 3) 
affinity_card_prob 
FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY cust_id;

-- PREDICTION_SET -------------------------------------------------------------
-- Explanation:
-- Here R script DT_RDEMO_SCORE_CLASSIFICATION is used to get the 
-- PREDICTION set. Actual target value and predicted target values are provided. 

SELECT T.CUST_ID, T.affinity_card, S.PREDICTION, 
round(S.probability, 3) as probability
FROM (SELECT CUST_ID, affinity_card, 
PREDICTION_SET(DT_RDEMO_CLASSIFICATION USING *) pset 
FROM mining_data_apply_v WHERE CUST_ID <= 100010) T, TABLE(T.pset) S 
WHERE S.probability > 0 ORDER BY T.CUST_ID, S.PREDICTION;

-- PREDICTION_DETAILS ---------------------------------------------------------
-- Explanation:
-- The R script DT_RDEMO_WEIGHT_CLASSIFICATION is used to get the PREDICTION 
-- details. The CUST_ID and PREDICTION details with each attribute weight
-- are provided.

column pred_det format a65;

SELECT CUST_ID, PREDICTION_DETAILS(DT_RDEMO_CLASSIFICATION, '1' USING *) pred_det
FROM mining_data_apply_v WHERE EDUCATION = 'Bach.' and HOUSEHOLD_SIZE = '3'
and CUST_ID <= 100080 ORDER BY CUST_ID;

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('DT_RDEMO_REGRESSION');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('DT_RDEMO_CLASSIFICATION');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE DT_RDEMO_SETTINGS_RE';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE DT_RDEMO_SETTINGS_CL';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
