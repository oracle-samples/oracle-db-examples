-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   Regression - Neural Networks Algorithm - dmnnrdem.sql
--   
--   Copyright (c) 2025 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic, purchase, and affinity card membership data for a 
-- set of customers, predict customer's age. Since age is a continuous 
-- variable, this is a regression problem.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in the SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).
--
-----------
-- ANALYSIS
-----------
-- For regression using NN, perform the following on mining data.
--
-- 1. Use Auto Data Preparation
--

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with same name (if any)
BEGIN DBMS_DATA_MINING.DROP_MODEL('NNR_SH_Regr_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nnr_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create settings for neural network
--
SET echo off
CREATE TABLE nnr_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
SET echo on 
BEGIN       
  -- Populate settings table
  INSERT INTO nnr_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.algo_name,dbms_data_mining.algo_neural_network);
  INSERT INTO nnr_sh_sample_settings (setting_name, setting_value) VALUES 
  (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
  INSERT INTO nnr_sh_sample_settings (setting_name, setting_value) VALUES 
  (dbms_data_mining.odms_random_seed, '12');

  -- Examples of other possible settings are:
  --(dbms_data_mining.nnet_hidden_layers, '2');
  --(dbms_data_mining.nnet_nodes_per_layer, '10, 30');
  --(dbms_data_mining.nnet_iterations, '100');
  --(dbms_data_mining.nnet_tolerance, '0.0001');
  --(dbms_data_mining.nnet_activations, 
  --   ''''|| dbms_data_mining.nnet_activations_log_sig ||'''');
  --(dbms_data_mining.nnet_regularizer, 
  --        dbms_data_mining.nnet_regularizer_heldaside);
  --(dbms_data_mining.nnet_heldaside_ratio, '0.3');
  --(dbms_data_mining.nnet_heldaside_max_fail, '5');
  --(dbms_data_mining.nnet_regularizer,
  --        dbms_data_mining.nnet_regularizer_l2);
  --(dbms_data_mining.nnet_reg_lambda, '0.5');
  --(dbms_data_mining.nnet_weight_upper_bound, '0.7');
  --(dbms_data_mining.nnet_weight_lower_bound, '-0.6')
  --(dbms_data_mining.lbfgs_history_depth, '20');
  --(dbms_data_mining.lbfgs_scale_hessian, 
  --        dbms_data_mining.lbfgs_scale_hessian_disable);
  --(dbms_data_mining.lbfgs_gradient_tolerance, '0.0001');
  
END;
/

---------------------
-- CREATE A NEW MODEL
--
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'NNR_SH_Regr_sample',
    mining_function     => dbms_data_mining.regression,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'age',
    settings_table_name => 'nnr_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'NNR_SH_REGR_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
col attribute_name format a30
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'NNR_SH_REGR_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
WHERE model_name='NNR_SH_REGR_SAMPLE'
ORDER BY view_name;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--

-- 1. Root Mean Square Error - Sqrt(Mean((y - y')^2))
--
column rmse format 9999.99
SELECT SQRT(AVG((prediction - age) * (prediction - age))) rmse
  FROM (select age, PREDICTION(nnr_sh_regr_sample USING *) prediction
        from mining_data_test_v);

-- 2. Mean Absolute Error - Mean(|(y - y')|)
--
column mae format 9999.99
SELECT AVG(ABS(prediction - age)) mae
  FROM (select age, PREDICTION(nnr_sh_regr_sample USING *) prediction
        from mining_data_test_v);

-- 3. Residuals
--    If the residuals show substantial variance between
--    the predicted value and the actual, you can consider
--    changing the algorithm parameters.
--
column prediction format 99.9999
SELECT prediction, (prediction - age) residual
  FROM (select age, PREDICTION(nnr_sh_regr_sample USING *) prediction
        from mining_data_test_v)
 WHERE prediction < 17.5
 ORDER BY prediction;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- Predict the average age of customers, broken out by gender.
--
column cust_gender format a12
SELECT A.cust_gender,
       COUNT(*) AS cnt,
       ROUND(
       AVG(PREDICTION(nnr_sh_regr_sample USING A.*)),4)
       AS avg_age
  FROM mining_data_apply_v A
GROUP BY cust_gender
ORDER BY cust_gender;

------------------
-- BUSINESS CASE 2
-- Create a 10 bucket histogram of customers from Italy based on their age
-- and return each customer's age group.
--
column pred_age format 999.99
SELECT cust_id,
       PREDICTION(nnr_sh_regr_sample USING *) pred_age,
       WIDTH_BUCKET(
        PREDICTION(nnr_sh_regr_sample USING *), 10, 100, 10) "Age Group"
  FROM mining_data_apply_v
 WHERE country_name = 'Italy'
ORDER BY pred_age;

------------------
-- BUSINESS CASE 3
-- Find the reasons (8 attributes with the most impact) for the
-- predicted age of customer 100001.
--
set long 2000
set line 200
set pagesize 100
SELECT PREDICTION_DETAILS(nnr_sh_regr_sample, null, 8 USING *) prediction_details
  FROM mining_data_apply_v
 WHERE cust_id = 100001;

