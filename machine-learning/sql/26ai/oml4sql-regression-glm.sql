-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   Regression - Generalized Linear Model Algorithm - dmglrdem.sql
--   
--   Copyright (c) 2026 Oracle Corporation and/or its affilitiates.
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
-- Data preparation for GLM is performed internally

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with same name (if any)
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('GLMR_SH_Regr_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE glmr_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE glmr_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

-- Turn on feature selection and generation
--  
BEGIN 
-- Populate settings table
  INSERT INTO glmr_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_generalized_linear_model);
  -- output row diagnostic statistics
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.glms_row_diagnostics,
    dbms_data_mining.glms_row_diag_enable); 
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);  
  -- turn on feature selection
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES  
    (dbms_data_mining.glms_ftr_selection, 
    dbms_data_mining.glms_ftr_selection_enable);
  -- turn on feature generation
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES 
    (dbms_data_mining.glms_ftr_generation, 
    dbms_data_mining.glms_ftr_generation_enable); 
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES 
    (dbms_data_mining.glms_ftr_gen_method, 
    dbms_data_mining.glms_ftr_gen_quadratic);
  /* Examples of possible overrides are shown below. If the user does not
     override, then relevant settings are determined by the algorithm
      
  -- specify a row weight column 
    (dbms_data_mining.odms_row_weight_column_name,<row_weight_column_name>);
  -- specify a missing value treatment method:
     Default:  replace with mean (numeric features) or 
               mode (categorical features) 
       or delete the row
    (dbms_data_mining.odms_missing_value_treatment,
      dbms_data_mining.odms_missing_value_delete_row);
  -- turn ridge regression on or off 
     By default the system turns it on if there is a multicollinearity
    (dbms_data_mining.glms_ridge_regression,
     dbms_data_mining.glms_ridge_reg_enable);  
  */  
END;
/ 

CREATE OR replace VIEW mdb_rdemo_v AS 
  SELECT cust_id, age, bookkeeping_application, bulk_pack_diskettes,
    cust_marital_status, home_theater_package, household_size, occupation,
    yrs_residence, y_box_games FROM mining_data_build_v;
---------------------
-- CREATE A NEW MODEL
--
-- Force the column affinity_card to be a feature in the model using
-- dbms_data_mining_transform
--
declare
  v_xlst dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
  -- Force the column affinity_card to be a feature in the model
  dbms_data_mining_transform.set_transform(v_xlst,
    'HOME_THEATER_PACKAGE', NULL, 'HOME_THEATER_PACKAGE', 
    'HOME_THEATER_PACKAGE', 'FORCE_IN');
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'GLMR_SH_Regr_sample',
    mining_function     => dbms_data_mining.regression,
    data_table_name     => 'mdb_rdemo_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'age',
    settings_table_name => 'glmr_sh_sample_settings',
    xform_list          => v_xlst);
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'GLMR_SH_REGR_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'GLMR_SH_REGR_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- IF the covariance matrix had been invalid, THEN the global details 
-- would have had a row like:
--
--   VALID_COVARIANCE_MATRIX  0 
-- 
-- And, as a result we would only have gotten a limited set of diagnostics.
-- This never happens with feature selecion enabled. IF the forced in feature 
-- had caused a multi-collinearity then the model build would have failed.
-- Note that the forced_in feature, age, was not statistically significant.
-- However, it did not cause a multi-collinearity, hence the build succeeded.
--
-- With feature selection disabled, then an invalid covariance matrix is 
-- possible. Then, multi-collinearity, if it exists will cause 
-- RIDGE REGRESSION to kick in, unless it has been specifically disabled by 
-- you. The build will succeed with ridge enabled. However, the covariance 
-- matrix will be invalid since it is not computed by the ridge algorithm.
-- 
-- An important consequence of an invalid covariance matrix is that
-- the model cannot predict confidence bounds - i.e. the result of
-- PREDICTION_BOUNDS function in a SQL query is NULL.
--
-- If accuracy is the primary goal and interpretability not important, then we
-- note that RIDGE REGRESSION may be preferrable to feature selection for 
-- some datasets. You can test this by specifically enabling ridge regression.
-- 
-- In this demo, we compute two models. The first (above) has feature
-- selection enabled and produces confidence bounds and a full set of 
-- diagnostics. The second enables ridge regression. It does not produce 
-- confidence bounds. It only produces a limited set of diagnostics.

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='GLMR_SH_REGR_SAMPLE'
  ORDER BY view_name;

-- Global GLM model statistics
column numeric_value format 9999990.999
column string_value format a20
select name, numeric_value, string_value from DM$VGGLMR_SH_REGR_SAMPLE
  ORDER BY name;

-- Coefficient statistics
SET line 120
column feature_expression format a53 
column coefficient format 9999990.999
column std_error format 9999990.999 
column test_statistic format 9999990.999  
column p_value format 9999990.999  
column std_coefficient format 9999990.999  
column lower_coeff_limit format 9999990.999 
column upper_coeff_limit format 9999990.999  
  SELECT feature_expression, coefficient, std_error, test_statistic,
  p_value, std_coefficient, lower_coeff_limit, upper_coeff_limit
  FROM DM$VDGLMR_SH_REGR_SAMPLE
  ORDER BY 1;

-- Show the features and their p_values
SET lin 80
SET pages 20
  SELECT feature_expression, coefficient, p_value 
  FROM DM$VDGLMR_SH_REGR_SAMPLE
  ORDER BY feature_expression;

-- Row diagnostics
SELECT CASE_id, TARGET_value, PREDICTED_TARGET_value, hat, 
  residual, std_err_residual, studentized_residual, pred_res, cooks_d
  FROM dm$vaGLMR_SH_Regr_sample
 WHERE case_id <= 101510
 ORDER BY case_id;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

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
  FROM (SELECT cust_id, prediction(GLMR_SH_Regr_sample using *) pred
          FROM mining_data_test_v) A,
       mining_data_test_v B
  WHERE A.cust_id = B.cust_id;

-----------------------------------------------------------------------
--                               SCORE NEW DATA
-----------------------------------------------------------------------

-- Since the model has a valid covariance matrix, it is possible
-- to obtain confidence bounds.
-- In addition, provide details to help explain the prediction
set long 20000
set line 200
set pagesize 100
SELECT CUST_ID,
       PREDICTION(GLMR_SH_Regr_sample USING *) pr,
       PREDICTION_BOUNDS(GLMR_SH_Regr_sample USING *).lower pl,
       PREDICTION_BOUNDS(GLMR_SH_Regr_sample USING *).upper pu,
       PREDICTION_DETAILS(GLMR_SH_Regr_sample USING *) pd
  FROM mining_data_apply_v
 WHERE CUST_ID < 100010
 ORDER BY CUST_ID;

-- Next we compare to a model built with ridge regression enabled


-----------------------------------------------------------------------
--                            BUILD A NEW MODEL
-----------------------------------------------------------------------

---------------------
-- CREATE A NEW MODEL
--
-- Cleanup old model with same name (if any)
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('GLMR_SH_Regr_sample');
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/

-- SPECIFY SETTINGS
--
-- Cleanup old settings table 
BEGIN EXECUTE IMMEDIATE 'DROP TABLE glmr_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE glmr_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

-- Turn on ridge regression
--  
BEGIN 
-- Populate settings table
  INSERT INTO glmr_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_generalized_linear_model);
  -- output row diagnostic statistics
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.glms_row_diagnostics,
    dbms_data_mining.glms_row_diag_enable); 
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);  
  -- turn on ridge regression
  INSERT INTO  glmr_sh_sample_settings (setting_name, setting_value) VALUES  
    (dbms_data_mining.glms_ridge_regression,
    dbms_data_mining.glms_ridge_reg_enable);  
  INSERT INTO glmr_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.GLMS_SOLVER, 
    dbms_data_mining.GLMS_SOLVER_QR); 
END;
/

BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'GLMR_SH_Regr_sample',
    mining_function     => dbms_data_mining.regression,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'age',
    settings_table_name => 'glmr_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'GLMR_SH_REGR_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'GLMR_SH_REGR_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='GLMR_SH_REGR_SAMPLE'
  ORDER BY view_name;

-- Global GLM model statistics
column name format a30
column numeric_value format 9999990.999
column string_value format a20
select name, numeric_value, string_value from DM$VGGLMR_SH_REGR_SAMPLE
  ORDER BY name;

-- Coefficient statistics
SET line 120
column attribute_name format a20  
column attribute_subname format a20
column attribute_value format a20 
column partition_name format a20
column vif format 9999990.999 
column exp_coefficient format 9999990.999  
column exp_lower_coeff_limit format 9999990.999  
column exp_upper_coeff_limit format 9999990.999
  SELECT *
  FROM DM$VDGLMR_SH_REGR_SAMPLE
 WHERE attribute_name in ('AFFINITY_CARD','BULK_PACK_DISKETTES','COUNTRY_NAME')
ORDER BY attribute_name, attribute_value;
    
-- Limited row diagnostics - residuals only, others are NULL
SELECT CASE_id, TARGET_value, PREDICTED_TARGET_value, residual
  FROM dm$vaGLMR_SH_Regr_sample
 WHERE case_id <= 101510
 ORDER BY case_id;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

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
  FROM (SELECT cust_id, prediction(GLMR_SH_Regr_sample using *) pred
          FROM mining_data_test_v) A,
       mining_data_test_v B
 WHERE A.cust_id = B.cust_id;

-- 3. Residuals
--    If the residuals show substantial variance between
--    the predicted value and the actual, you can consider
--    changing the algorithm parameters.
--
SELECT TO_CHAR(ROUND(pred, 4)) prediction, residual
  FROM (SELECT A.pred, (A.pred - B.age) residual
          FROM (SELECT cust_id, prediction(GLMR_SH_Regr_sample using *) pred
                  FROM mining_data_test_v) A,
               mining_data_test_v B
         WHERE A.cust_id = B.cust_id
        ORDER BY A.pred ASC)
 WHERE pred <= 18.388
 ORDER BY pred;

-----------------------------------------------------------------------
--                               SCORE NEW DATA
-----------------------------------------------------------------------

-- Now that the model has an invalid covariance matrix, it is 
-- no longer possible to obtain confidence bounds.
-- So the lower (PL) and upper (PU) confidence bounds are NULL
set long 20000
set line 200
set pagesize 100
SELECT CUST_ID,
       PREDICTION(GLMR_SH_Regr_sample USING *) pr,
       PREDICTION_BOUNDS(GLMR_SH_Regr_sample USING *).lower pl,
       PREDICTION_BOUNDS(GLMR_SH_Regr_sample USING *).upper pu,
       PREDICTION_DETAILS(GLMR_SH_Regr_sample USING *) pd
  FROM mining_data_apply_v
 WHERE CUST_ID < 100010
 ORDER BY CUST_ID;
