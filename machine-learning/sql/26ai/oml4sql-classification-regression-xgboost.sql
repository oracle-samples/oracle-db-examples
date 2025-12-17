-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   Classification and Regression - XGBoost Algorithm
--   
--   Copyright (c) 2025 Oracle Corporation and/or its affilitiates.
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
SET LONG 20000
-----------------------------------------------------------------------
--                (1) Use XGBoost for classification
-----------------------------------------------------------------------

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic and purchase data about a set of customers, predict
-- customer's response to an affinity card program using XGboost
--

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-------
-- DATA
-------
-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- (See dmsh.sql for view definitions).
--
-- Cleanup old settings table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE xgc_sh_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Cleanup old model with the same name
BEGIN DBMS_DATA_MINING.DROP_MODEL('XGC_SH_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE xgc_sh_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
set echo on

BEGIN 
-- Populate settings table
  INSERT INTO xgc_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_xgboost);
  -- for 0/1 target, choose binary:logistic as objective
  INSERT INTO xgc_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_objective, 'binary:logistic');
  INSERT INTO xgc_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_max_depth, '3');
  INSERT INTO xgc_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_eta, '1');
  -- choose error and auc as eval_metric to evaluate training dataset
  INSERT INTO xgc_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_eval_metric, 'error,auc');
  INSERT INTO xgc_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_num_round, '10');
END;
/


---------------------
-- CREATE MODEL
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'XGC_SH_MODEL',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'xgc_sh_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'XGC_SH_MODEL'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'XGC_SH_MODEL'
ORDER BY attribute_name;

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='XGC_SH_MODEL'
  ORDER BY view_name;

-- Global statistics
column name format a30
column numeric_value format 9999990.999
column string_value format a20
select name, numeric_value, string_value 
  from DM$VGXGC_SH_MODEL
  ORDER BY name;

--attribute importance: top 10 important features
column attribute_name format a25
column attribute_value format a15
column gain format 9.999
column cover format 9.999
column frequency format 9.999

select * from(
select attribute_name, attribute_value, gain, cover, frequency 
from DM$VIXGC_SH_MODEL
order by gain desc)
where rownum <= 10;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------
------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--
-- The queries shown below demonstrate the use of new SQL data mining functions
-- along with analytic functions to compute the various test metrics.
--
-- Modelname:             xgc_sh_model
-- Target attribute:      affinity_card
-- Positive target value: 1
-- (Change as appropriate for a different example)

-- Compute CONFUSION MATRIX
--
-- This query demonstates how to generate a confusion matrix using the new
-- SQL prediction functions for scoring. The returned columns match the
-- schema of the table generated by COMPUTE_CONFUSION_MATRIX procedure.
--
SELECT affinity_card AS actual_target_value,
       PREDICTION(XGC_SH_MODEL USING *) AS predicted_target_value,
       COUNT(*) AS value
  FROM mining_data_test_v
 GROUP BY affinity_card, PREDICTION(XGC_SH_MODEL USING *)
 ORDER BY 1, 2;

-- Compute ACCURACY
--
column accuracy format 9.99

SELECT SUM(correct)/COUNT(*) AS accuracy
  FROM (SELECT DECODE(affinity_card,
                 PREDICTION(XGC_SH_MODEL USING *), 1, 0) AS correct
          FROM mining_data_test_v);

-- Compute AUC (Area Under the roc Curve)
column auc format 9.99
WITH
pos_prob_and_counts AS (
SELECT PREDICTION_PROBABILITY(XGC_SH_MODEL, 1 USING *) pos_prob,
       DECODE(affinity_card, 1, 1, 0) pos_cnt
  FROM mining_data_test_v
),
tpf_fpf AS (
SELECT  pos_cnt,
       SUM(pos_cnt) OVER (ORDER BY pos_prob DESC) /
         SUM(pos_cnt) OVER () tpf,
       SUM(1 - pos_cnt) OVER (ORDER BY pos_prob DESC) /
         SUM(1 - pos_cnt) OVER () fpf
  FROM pos_prob_and_counts
),
trapezoid_areas AS (
SELECT 0.5 * (fpf - LAG(fpf, 1, 0) OVER (ORDER BY fpf, tpf)) *
        (tpf + LAG(tpf, 1, 0) OVER (ORDER BY fpf, tpf)) area
  FROM tpf_fpf
 WHERE pos_cnt = 1
    OR (tpf = 1 AND fpf = 1)
)
SELECT SUM(area) auc
  FROM trapezoid_areas;

-----------------------------------------------------------------------
--                (2) Use XGBoost for regression
-----------------------------------------------------------------------

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic and purchase data about a set of customers, predict
-- customer's response to an affinity card program using XGboost
--

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-------
-- DATA
-------
-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- (See dmsh.sql for view definitions).
--
-----------------------------------------------------------------------
-- Cleanup old settings table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE xgr_sh_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Cleanup old model with the same name
BEGIN DBMS_DATA_MINING.DROP_MODEL('XGR_SH_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE xgr_sh_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
set echo on

BEGIN 
-- Populate settings table
  INSERT INTO xgr_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_xgboost);
  -- for 0/1 target, choose binary:logistic as objective
  INSERT INTO xgr_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_booster, 'gblinear');
  INSERT INTO xgr_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_alpha, '0.0001');
  INSERT INTO xgr_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_lambda, '1');
  INSERT INTO xgr_sh_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.xgboost_num_round, '100');
END;
/

---------------------
-- CREATE MODEL
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'XGR_SH_MODEL',
    mining_function     => dbms_data_mining.regression,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'age',
    settings_table_name => 'xgr_sh_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'XGR_SH_MODEL'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'XGR_SH_MODEL'
ORDER BY attribute_name;

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='XGR_SH_MODEL'
  ORDER BY view_name;

-- Global statistics
column name format a30
column numeric_value format 9999990.999
column string_value format a20
select name, numeric_value, string_value 
  from DM$VGXGR_SH_MODEL
  ORDER BY name;

-- attribute importance
-- show top 5
column ATTRIBUTE_NAME format a25;
column ATTRIBUTE_VALUE format a15;
column weight format 9.999
select * from(
select attribute_name, attribute_value, weight
from DM$VIXGR_SH_MODEL
order by abs(weight) desc) 
where rownum <= 5;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------
------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--
-- The queries shown below demonstrate the use of new SQL data mining functions
-- along with analytic functions to compute the various test metrics.
--
-- Modelname:             xgr_sh_model
-- Target attribute:      age

------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--

-- 1. Root Mean Square Error - Sqrt(Mean((x - x')^2))
-- 2. Mean Absolute Error - Mean(|(x - x')|)
--
column rmse format 9999.9
column mae format 9999.9  
SELECT SQRT(AVG((A.pred - B.age) * (A.pred - B.age))) rmse,
       AVG(ABS(a.pred - B.age)) mae
  FROM (SELECT cust_id, prediction(XGR_SH_MODEL using *) pred
          FROM mining_data_test_v) A,
       mining_data_test_v B
  WHERE A.cust_id = B.cust_id;

--- prediction
SELECT CUST_ID, age,
       PREDICTION(XGR_SH_MODEL USING *) pred,
       PREDICTION_DETAILS(XGR_SH_MODEL USING *) det
  FROM mining_data_apply_v
 WHERE CUST_ID < 100010
 ORDER BY CUST_ID;
