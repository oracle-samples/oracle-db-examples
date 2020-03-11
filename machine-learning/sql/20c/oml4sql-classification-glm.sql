-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   Classification - Generalized Linear Model Algorithm - dmglcdem.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic and purchase data about a set of customers, predict
-- customer's response to an affinity card program using a GLM classifier.
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
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).
--

-----------
-- ANALYSIS
-----------
-- Data preparation in GLM is performed internally
--

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with the same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('GLMC_SH_Clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE glmc_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE glmc_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
set echo on

-- The default classification algorithm is Naive Bayes. So override
-- this choice to GLM logistic regression using a settings table. 
-- Turn on feature selection and generation
--    
BEGIN 
-- Populate settings table
  INSERT INTO glmc_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_generalized_linear_model);
  -- output row diagnostic statistics 
  INSERT INTO  glmc_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.glms_row_diagnostics,
    dbms_data_mining.glms_row_diag_enable);
  INSERT INTO  glmc_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
  -- turn on feature selection
  INSERT INTO  glmc_sh_sample_settings (setting_name, setting_value) VALUES  
    (dbms_data_mining.glms_ftr_selection, 
    dbms_data_mining.glms_ftr_selection_enable);
  -- turn on feature generation
  INSERT INTO  glmc_sh_sample_settings (setting_name, setting_value) VALUES 
    (dbms_data_mining.glms_ftr_generation, 
    dbms_data_mining.glms_ftr_generation_enable); 
  
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

---------------------
-- CREATE A NEW MODEL
--
-- Force the column age to be a feature in the model using
-- dbms_data_mining_transform
--
declare
  v_xlst dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
  -- Force the column age to be a feature in the model
  dbms_data_mining_transform.set_transform(v_xlst,
    'AGE', NULL, 'AGE', 'AGE', 'FORCE_IN');
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'GLMC_SH_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'glmc_sh_sample_settings',
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
 WHERE model_name = 'GLMC_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'GLMC_SH_CLAS_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
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
  WHERE model_name='GLMC_SH_CLAS_SAMPLE'
  ORDER BY view_name;

-- Global statistics
column name format a30
column numeric_value format 9999990.999
column string_value format a20
select name, numeric_value, string_value from DM$VGGLMC_SH_CLAS_SAMPLE
  ORDER BY name;

-- Coefficient statistics
SET line 200
column feature_expression format a53 
column attr_name format a20
col attr_val format a10  
column coefficient format 9999990.999
column std_error format 9999990.999 
column test_statistic format 9999990.999  
column p_value format 9999990.999  
column std_coefficient format 9999990.999  
column lower_coeff_limit format 9999990.999 
column upper_coeff_limit format 9999990.999
column exp_coefficient format 9999990.999  
column exp_lower_coeff_limit format 9999990.999  
column exp_upper_coeff_limit format 9999990.999  
  
SELECT attribute_name attr_name, attribute_value attr_val, 
  coefficient, std_error, test_statistic,
  p_value, std_coefficient, lower_coeff_limit, upper_coeff_limit,
  exp_coefficient, exp_lower_coeff_limit, exp_upper_coeff_limit
  FROM DM$VDGLMC_SH_CLAS_SAMPLE
  ORDER BY 1,2;

-- Show the features and their p_values
SET lin 80
SET pages 20
SELECT attribute_name attr_name, attribute_value attr_val, coefficient, p_value 
  FROM DM$VDGLMC_SH_CLAS_SAMPLE
  ORDER BY p_value;
    
-- Row diagnostics
SELECT CASE_id, TARGET_value, TARGET_value_prob, hat, 
  working_residual, pearson_residual, deviance_residual, 
  c, cbar, difdev, difchisq
  FROM dm$vaGLMC_SH_Clas_sample
 WHERE case_id <= 101510
 ORDER BY case_id;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------
------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--
-- The queries shown below demonstrate the use of new SQL data mining functions
-- along with analytic functions to compute the various test metrics.
--
-- Modelname:             glmc_sh_clas_sample
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
       PREDICTION(glmc_sh_clas_sample USING *) AS predicted_target_value,
       COUNT(*) AS value
  FROM mining_data_test_v
 GROUP BY affinity_card, PREDICTION(glmc_sh_clas_sample USING *)
 ORDER BY 1, 2;

-- Compute ACCURACY
--
column accuracy format 9.99

SELECT SUM(correct)/COUNT(*) AS accuracy
  FROM (SELECT DECODE(affinity_card,
                 PREDICTION(glmc_sh_clas_sample USING *), 1, 0) AS correct
          FROM mining_data_test_v);
  
-- Compute AUC (Area Under the roc Curve)
-- (See notes on ROC Curve and AUC computation in dmsvcdem.sql)
--
column auc format 9.99
WITH
pos_prob_and_counts AS (
SELECT PREDICTION_PROBABILITY(glmc_sh_clas_sample, 1 USING *) pos_prob,
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

--------------------------------------------------------------------------
--                               SCORE DATA
--------------------------------------------------------------------------

-- Since the model has a valid covariance matrix, it is possible
-- to obtain confidence bounds.  In addition, provide the ranked set
-- of attributes which have the most influence on each prediction.
set long 10000
SELECT PREDICTION(GLMC_SH_Clas_sample USING *) pr,
       PREDICTION_PROBABILITY(GLMC_SH_Clas_sample USING *) pb,
       PREDICTION_BOUNDS(GLMC_SH_Clas_sample USING *).lower pl,
       PREDICTION_BOUNDS(GLMC_SH_Clas_sample USING *).upper pu,
       PREDICTION_DETAILS(GLMC_SH_Clas_sample USING *) pd
  FROM mining_data_apply_v
 WHERE CUST_ID <= 100010
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
  DBMS_DATA_MINING.DROP_MODEL('GLMC_SH_Clas_sample');
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/

-- SPECIFY SETTINGS
--
-- Cleanup old settings table 
BEGIN EXECUTE IMMEDIATE 'DROP TABLE glmc_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE glmc_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

-- Turn on ridge regression
--  
BEGIN 
-- Populate settings table
  INSERT INTO glmc_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_generalized_linear_model);
  -- output row diagnostic statistics into a table named GLMC_SH_SAMPLE_DIAG  
  INSERT INTO  glmc_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.glms_row_diagnostics,
    dbms_data_mining.glms_row_diag_enable); 
  INSERT INTO  glmc_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);  
  -- turn on ridge regression
  INSERT INTO  glmc_sh_sample_settings (setting_name, setting_value) VALUES  
    (dbms_data_mining.glms_ridge_regression,
    dbms_data_mining.glms_ridge_reg_enable);  
  INSERT INTO glmc_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.GLMS_SOLVER, 
     dbms_data_mining.GLMS_SOLVER_QR); 
END;
/
commit;

BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'GLMC_SH_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'glmc_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'GLMC_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'GLMC_SH_CLAS_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='GLMC_SH_CLAS_SAMPLE'
  ORDER BY view_name;

-- Global statistics
column numeric_value format 9999990.999
column string_value format a20
select name, numeric_value, string_value from DM$VGGLMC_SH_CLAS_SAMPLE
  ORDER BY name;

-- Coefficient statistics
SET line 120
column class format a20
column attribute_name format a20  
column attribute_subname format a20
column attribute_value format a20  
column partition_name format a20
  
SELECT *
  FROM DM$VDGLMC_SH_CLAS_SAMPLE
 WHERE attribute_name = 'OCCUPATION'
 ORDER BY target_value, attribute_name, attribute_value;
    
-- Limited row diagnostics - working_residuals only, others are NULL
SELECT CASE_id, TARGET_value, TARGET_value_prob, working_residual
  FROM dm$vaGLMC_SH_Clas_sample
 WHERE case_id <= 101510
 ORDER BY case_id;

-----------------------------------------------------------------------
--                               TEST THE NEW MODEL
-----------------------------------------------------------------------
------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--
-- The queries shown below demonstrate the use of new SQL data mining functions
-- along with analytic functions to compute various test metrics. 
--
-- Modelname:             glmc_sh_clas_sample
-- Target attribute:      affinity_card
-- Positive target value: 1
-- (Change these as appropriate for a different example)

-- Compute CONFUSION MATRIX
--
-- This query demonstates how to generate a confusion matrix using the new
-- SQL prediction functions for scoring. The returned columns match the
-- schema of the table generated by COMPUTE_CONFUSION_MATRIX procedure.
--
SELECT affinity_card AS actual_target_value,
       PREDICTION(glmc_sh_clas_sample USING *) AS predicted_target_value,
       COUNT(*) AS value
  FROM mining_data_test_v
 GROUP BY affinity_card, PREDICTION(glmc_sh_clas_sample USING *)
 ORDER BY 1, 2;

-- Compute ACCURACY
--
column accuracy format 9.99

SELECT SUM(correct)/COUNT(*) AS accuracy
  FROM (SELECT DECODE(affinity_card,
                 PREDICTION(glmc_sh_clas_sample USING *), 1, 0) AS correct
          FROM mining_data_test_v);

-- Compute AUC (Area Under the roc Curve)
--
-- See notes on ROC Curve and AUC computation above
--
column auc format 9.99
WITH
pos_prob_and_counts AS (
SELECT PREDICTION_PROBABILITY(glmc_sh_clas_sample, 1 USING *) pos_prob,
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

-- Judging from the accuracy and AUC, the ridge regression model 
-- and feature selection/generation model are of approximately equal 
-- quality

--------------------------------------------------------------------------
--                               SCORE DATA
--------------------------------------------------------------------------

-- Now that the model has an invalid covariance matrix, it is 
-- no longer possible to obtain confidence bounds.
-- So the lower (PL) and upper (PU) confidence bounds are NULL
set long 10000
SELECT PREDICTION(GLMC_SH_Clas_sample USING *) pr,
       PREDICTION_PROBABILITY(GLMC_SH_Clas_sample USING *) pb,
       PREDICTION_BOUNDS(GLMC_SH_Clas_sample USING *).lower pl,
       PREDICTION_BOUNDS(GLMC_SH_Clas_sample USING *).upper pu,
       PREDICTION_DETAILS(GLMC_SH_Clas_sample USING *) pd
  FROM mining_data_apply_v
 WHERE CUST_ID <= 100010
 ORDER BY CUST_ID;
