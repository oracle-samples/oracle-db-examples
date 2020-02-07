Rem
Rem $Header: rdbms/demo/dmsvodem.sql /main/11 2016/08/16 23:01:14 madhpand Exp $
Rem
Rem dmsvodem.sql
Rem
Rem Copyright (c) 2004, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmsvodem.sql - Sample program for the DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates an anomaly detection model
Rem      for data analysis and outlier identification using the 
Rem      one-class SVM algorithm 
Rem      and data in the SH (Sales History)schema in the RDBMS. 
Rem
Rem    NOTES
Rem    
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    madhpand    07/15/16 - set parallel 4
Rem    jiangzho    02/17/16 - fix a typo involving SVMO
Rem    bmilenov    09/29/15 - bug-21394151: view cleanup
Rem    amozes      01/23/12 - updates for 12c
Rem    xbarr       01/10/12 - add prediction_details demo
Rem    ramkrish    06/14/07 - remove commit after settings
Rem    ramkrish    10/25/07 - replace deprecated get_model calls with catalog
Rem                           queries
Rem    ktaylor     07/11/05 - minor edits to comments
Rem    jcjeon      01/18/05 - add column format 
Rem    bmilenov    10/28/04 - bmilenov_oneclass_demo
Rem    bmilenov    10/25/04 - Remove dbms_output statements 
Rem    bmilenov    10/22/04 - Comment revision 
Rem    bmilenov    10/20/04 - Created
Rem

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographics about a set of customers that are known to have 
-- an affinity card, 1) find the most atypical members of this group 
-- (outlier identification), 2) discover the common demographic 
-- characteristics of the most typical customers with affinity card, 
-- and 3) compute how typical a given new/hypothetical customer is.
--
-------
-- DATA
-------
-- The data for this sample is composed from base tables in the SH schema
-- (See Sample Schema Documentation) and presented through a view:
-- mining_data_one_class_pv
-- (See dmsh.sql for view definition).
--
--

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with the same name (if any)
BEGIN DBMS_DATA_MINING.DROP_MODEL('SVMO_SH_Clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

--------------------------------
-- PREPARE DATA
--
-- Automatic data preparation is used.

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table (if any)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE svmo_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/

-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE svmo_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
set echo on

BEGIN       
  -- Populate settings table
  -- SVM needs to be selected explicitly (default classifier: Naive Bayes)
   
  -- Examples of other possible overrides are:
  -- select a different rate of outliers in the data (default 0.1)
  -- (dbms_data_mining.svms_outlier_rate, ,0.05);
  -- select a kernel type (default kernel: selected by the algorithm)
  -- (dbms_data_mining.svms_kernel_function, dbms_data_mining.svms_linear);
  -- (dbms_data_mining.svms_kernel_function, dbms_data_mining.svms_gaussian);
   
  INSERT INTO svmo_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.algo_name, dbms_data_mining.algo_support_vector_machines);  
  INSERT INTO svmo_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
END;
/

---------------------
-- CREATE A MODEL
--
-- Build a new one-class SVM Model
-- Note the NULL sprecification for target column name
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'SVMO_SH_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_one_class_pv',
    case_id_column_name => 'cust_id',
    target_column_name  => NULL,
    settings_table_name => 'svmo_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'SVMO_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
-- For sample code displaying SVM signature see dmsvcdem.sql.

------------------------
-- DISPLAY MODEL DETAILS
--
-- Model details are available only for SVM models with linear kernel.
-- For SVM model details sample code see dmsvcdem.sql.
--
-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
WHERE model_name='SVMO_SH_CLAS_SAMPLE'
ORDER BY view_name;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

-- Depending on the business case, the model can be scored against the
-- build data (e.g, business cases 1 and 2) or against new, previously
-- unseen data (e.g., business case 3). New apply data needs to undergo 
-- the same transformations as the build data (see business case 3).

------------------
-- BUSINESS CASE 1
-- Find the top 5 outliers - customers that differ the most from 
-- the rest of the population. Depending on the application, such 
-- atypical customers can be removed from the data (data cleansing).
-- Explain which attributes cause them to appear different.
--
set long 20000
col pd format a90
SELECT cust_id, pd FROM
(SELECT cust_id,
        PREDICTION_DETAILS(SVMO_SH_Clas_sample, 0 using *) pd,
        rank() over (order by prediction_probability(
                     SVMO_SH_Clas_sample, 0 using *) DESC, cust_id) rnk
 FROM mining_data_one_class_pv)
WHERE rnk <= 5
order by rnk;

------------------
-- BUSINESS CASE 2
-- Find demographic characteristics of the typical affinity card members.
-- These statistics will not be influenced by outliers and are likely to
-- provide a more truthful picture of the population of interest than
-- statistics computed on the entire group of affinity members.
-- Statistics are computed on the original (non-transformed) data.
column cust_gender format a12
SELECT cust_gender, round(avg(age)) age, 
       round(avg(yrs_residence)) yrs_residence,
       count(*) cnt
FROM mining_data_one_class_pv
WHERE prediction(SVMO_SH_Clas_sample using *) = 1
GROUP BY cust_gender
ORDER BY cust_gender;  


------------------
-- BUSINESS CASE 3
-- 
-- Compute probability of a new/hypothetical customer being a typical  
-- affinity card holder.
-- Necessary data preparation on the input attributes is performed
-- automatically during model scoring since the model was build with
-- auto data prep.
--
column prob_typical format 9.99
select prediction_probability(SVMO_SH_Clas_sample, 1 using 
                             44 AS age,
                             6 AS yrs_residence,
                             'Bach.' AS education,
                             'Married' AS cust_marital_status,
                             'Exec.' AS occupation,
                             'United States of America' AS country_name,
                             'M' AS cust_gender,
                             'L: 300,000 and above' AS cust_income_level,
                             '3' AS household_size
                             ) prob_typical
from dual;

-----------------------------------------------------------------------
--    BUILD and APPLY a transient model using analytic functions
-----------------------------------------------------------------------
-- In addition to creating a persistent model that is stored as a schema
-- object, models can be built and scored on data on the fly using
-- Oracle's analytic function syntax.

----------------------
-- BUSINESS USE CASE 4
-- 
-- Identify rows that are most atypical in the input dataset.
-- Consider each type of marital status to be separate, so the most
-- anomalous rows per marital status group should be returned.
-- Provide the top three attributes leading to the reason for the
-- record being an anomaly.
-- The partition by clause used in the analytic version of the
-- prediction_probability function will lead to separate models
-- being built and scored for each marital status.
col cust_marital_status format a30
select cust_id, cust_marital_status, rank_anom, anom_det FROM
(SELECT cust_id, cust_marital_status, anom_det,
        rank() OVER (PARTITION BY CUST_MARITAL_STATUS 
                     ORDER BY ROUND(ANOM_PROB,8) DESC,cust_id) rank_anom FROM
 (SELECT cust_id, cust_marital_status,
        PREDICTION_PROBABILITY(OF ANOMALY, 0 USING *) 
          OVER (PARTITION BY CUST_MARITAL_STATUS) anom_prob,
        PREDICTION_DETAILS(OF ANOMALY, 0, 3 USING *) 
          OVER (PARTITION BY CUST_MARITAL_STATUS) anom_det
   FROM mining_data_one_class_pv
 ))
where rank_anom < 3 order by 2, 3;
