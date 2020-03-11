-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 19c
-- 
--   Feature Extraction - Non-Negative Matrix Factorization Algorithm - dmnmdemo.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 100
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic data about a set of customers, extract features
-- from the given dataset.
--

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old settings table objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nmf_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('NMF_SH_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- CREATE A SETTINGS TABLE
--
-- NMF is the default Feature Extraction algorithm. For this sample,
-- we use Data Auto Preparation.
--
set echo off
CREATE TABLE nmf_sh_sample_settings (
   setting_name  VARCHAR2(30),
   setting_value VARCHAR2(4000));
set echo on
 
BEGIN
  -- Populate settings table
  insert into NMF_SH_SAMPLE_SETTINGS (SETTING_NAME, SETTING_VALUE) values
  (DBMS_DATA_MINING.PREP_AUTO,DBMS_DATA_MINING.PREP_AUTO_ON);
  -- Other examples of possible overrides are:
  -- (dbms_data_mining.feat_num_features, 10);
  -- (dbms_data_mining.nmfs_conv_tolerance,0.05);
  -- (dbms_data_mining.nmfs_num_iterations,50);
  -- (dbms_data_mining.nmfs_random_seed,-1);
END;
/     

---------------------
-- CREATE A NEW MODEL
--
-- Build NMF model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'NMF_SH_sample',
    mining_function     => dbms_data_mining.feature_extraction,
    DATA_TABLE_NAME     => 'mining_data_build_v',
    CASE_ID_COLUMN_NAME => 'cust_id',
    settings_table_name => 'nmf_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'NMF_SH_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'NMF_SH_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='NMF_SH_SAMPLE'
  ORDER BY view_name;

-- Each feature is a linear combination of the original attribute set; 
-- the coefficients of these linear combinations are non-negative.
-- The model details return for each feature the coefficients
-- associated with each one of the original attributes. Categorical 
-- attributes are described by (attribute_name, attribute_value) pairs.
-- That is, for a given feature, each distinct value of a categorical 
-- attribute has its own coefficient.
--
column attribute_name format a20;
column attribute_value format a60;
column coefficient format 9.99999
SELECT feature_id,
       attribute_name,
       attribute_value,
       coefficient
  FROM DM$VENMF_SH_Sample
WHERE feature_id = 1
  AND attribute_name in ('AFFINITY_CARD','AGE','COUNTRY_NAME')
ORDER BY feature_id,attribute_name,attribute_value;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------
-- There is no specific set of testing parameters for feature extraction.
-- Examination and analysis of features is the main method to prove
-- the efficacy of an NMF model.
--

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
--
-- For a descriptive mining function like feature extraction, "Scoring"
-- involves providing the probability values for each feature.
-- During model apply, an NMF model maps the original data into the 
-- new set of attributes (features) discovered by the model.
-- 

-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the features that correspond to customers in this dataset.
-- The feature that is returned for each row is the one with the
-- largest value based on the inputs for that row.
-- Count the number of rows that have the same "largest" feature value.
--
SELECT FEATURE_ID(nmf_sh_sample USING *) AS feat, COUNT(*) AS cnt
  FROM mining_data_apply_v
group by FEATURE_ID(NMF_SH_SAMPLE using *)
ORDER BY cnt DESC,FEAT DESC;

------------------
-- BUSINESS CASE 2
-- List top (largest) 3 features that represent a customer (100002).
-- Explain the attributes which most impact those features.
--
set line 120
column fid format 999
column val format 999.999
set long 20000
SELECT S.feature_id fid, value val,
       FEATURE_DETAILS(nmf_sh_sample, S.feature_id, 5 using T.*) det
FROM 
  (SELECT v.*, FEATURE_SET(nmf_sh_sample, 3 USING *) fset
    FROM mining_data_apply_v v
   WHERE cust_id = 100002) T, 
  TABLE(T.fset) S
order by 2 desc;
