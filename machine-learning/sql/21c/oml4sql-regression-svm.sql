-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 21c
-- 
--   Regression - SVM Algorithm - dmsvrdem.sql
--   
--   Copyright (c) 2021 Oracle Corporation and/or its affilitiates.
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
-- mining_data_build_parallel_v (build data)
-- mining_data_test_parallel_v  (test data)
-- mining_data_apply_parallel_v (apply data)
-- (See dmsh.sql for view definitions).
--
-----------
-- ANALYSIS
-----------
-- For regression using SVM, perform the following on mining data.
--
-- 1. Use Auto Data Preparation
--

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with same name (if any)
BEGIN DBMS_DATA_MINING.DROP_MODEL('SVMR_SH_Regr_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE svmr_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- The default algorithm for regression is SVM.
-- see dmsvcdem.sql on choice of kernel function.
-- 
SET echo off
CREATE TABLE svmr_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
SET echo on 
BEGIN       
  -- Populate settings table
  INSERT INTO svmr_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.svms_kernel_function, dbms_data_mining.svms_gaussian);

  INSERT INTO svmr_sh_sample_settings (setting_name, setting_value) VALUES 
  (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
  
  -- Examples of other possible overrides are:
  --(dbms_data_mining.svms_conv_tolerance,0.01);
  --(dbms_data_mining.svms_epsilon,0.1);
  --(dbms_data_mining.svms_kernel_function,dbms_data_mining.svms_linear);
END;
/

---------------------
-- CREATE A NEW MODEL
--
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'SVMR_SH_Regr_sample',
    mining_function     => dbms_data_mining.regression,
    data_table_name     => 'mining_data_build_parallel_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'age',
    settings_table_name => 'svmr_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'SVMR_SH_REGR_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
col attribute_name format a30
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'SVMR_SH_REGR_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- SVM model details are provided only for Linear Kernels.
-- The current model is built using a Gaussian Kernel (see dmsvcdem.sql).
--
-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
WHERE model_name='SVMR_SH_REGR_SAMPLE'
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
  FROM (select age, PREDICTION(svmr_sh_regr_sample USING *) prediction
        from mining_data_test_parallel_v);

-- 2. Mean Absolute Error - Mean(|(y - y')|)
--
column mae format 9999.99
SELECT AVG(ABS(prediction - age)) mae
  FROM (select age, PREDICTION(svmr_sh_regr_sample USING *) prediction
        from mining_data_test_parallel_v);

-- 3. Residuals
--    If the residuals show substantial variance between
--    the predicted value and the actual, you can consider
--    changing the algorithm parameters.
--
column prediction format 99.9999
SELECT prediction, (prediction - age) residual
  FROM (select age, PREDICTION(svmr_sh_regr_sample USING *) prediction
        from mining_data_test_parallel_v)
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
       AVG(PREDICTION(svmr_sh_regr_sample USING A.*)),4)
       AS avg_age
  FROM mining_data_apply_parallel_v A
GROUP BY cust_gender
ORDER BY cust_gender;

------------------
-- BUSINESS CASE 2
-- Create a 10 bucket histogram of customers from Italy based on their age
-- and return each customer's age group.
--
column pred_age format 999.99
SELECT cust_id,
       PREDICTION(svmr_sh_regr_sample USING *) pred_age,
       WIDTH_BUCKET(
        PREDICTION(svmr_sh_regr_sample USING *), 10, 100, 10) "Age Group"
  FROM mining_data_apply_parallel_v
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
SELECT PREDICTION_DETAILS(svmr_sh_regr_sample, null, 8 USING *) prediction_details
  FROM mining_data_apply_parallel_v
 WHERE cust_id = 100001;

-----------------------------------------------------------------------
--    BUILD and APPLY a transient model using analytic functions
-----------------------------------------------------------------------
-- In addition to creating a persistent model that is stored as a schema
-- object, models can be built and scored on data on the fly using
-- Oracle's analytic function syntax.

----------------------
-- BUSINESS USE CASE 4
-- 
-- Identify rows for which the provided value of the age column
-- does not match the expected value based on patterns in the data.
-- This could indicate bad data entry.
-- All necessary data preparation steps are automatically performed.
-- In addition, provide information as to what attributes most effect the
-- predicted value, where positive weights are pushing towards a larger
-- age and negative weights towards a smaller age.
set long 2000
set pagesize 100
col age_diff format 99.99
select cust_id, age, pred_age, age-pred_age age_diff, pred_det from
(select cust_id, age, pred_age, pred_det,
        rank() over (order by abs(age-pred_age) desc) rnk from
 (select cust_id, age, 
         prediction(for age using *) over () pred_age,
         prediction_details(for age ABS using *) over () pred_det
  from mining_data_apply_parallel_v))
where rnk <= 5;
