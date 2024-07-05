-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 23ai
-- 
--   Singular Value Decomposition Demo - dmsvddemo.sql
--   
--   Copyright (c) 2024 Oracle Corporation and/or its affilitiates.
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

-----------------------------------------------------------------------
--                            SAMPLE PROBLEMS
-----------------------------------------------------------------------
-- Extract SVD features for:
-- 1. Visualization 
-- 2. Data compression
-- Each use case will be illustrated separately.  
--
  
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- VISUALIZATIION USE CASE
--
-- Goal: Produce the top two PCA projections to visualize the data  
-----------------------------------------------------------------------  
-- Cleanup for repeat runs
-- Cleanup old data view
BEGIN EXECUTE IMMEDIATE 'DROP VIEW svd_sh_sample_build_num';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old settings table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE svd_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old model with the same name
BEGIN DBMS_DATA_MINING.DROP_MODEL('SVD_SH_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create a build data view with only numerical columns
CREATE VIEW svd_sh_sample_build_num AS
  SELECT CUST_ID, AGE, YRS_RESIDENCE, AFFINITY_CARD, BULK_PACK_DISKETTES,
    FLAT_PANEL_MONITOR, HOME_THEATER_PACKAGE, BOOKKEEPING_APPLICATION,
    PRINTER_SUPPLIES, Y_BOX_GAMES, OS_DOC_SET_KANJI 
  FROM MINING_DATA_BUILD_V;

-- Setting specification
-- Create settings table
set echo off
 CREATE TABLE svd_sh_sample_settings (
   setting_name  VARCHAR2(30),
   setting_value VARCHAR2(4000));
set echo on
  
-- Populate settings table
BEGIN       
  -- Select SVD as the Feature Extraction algorithm
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_singular_value_decomp);
  -- Turn on automatic data preparation
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_off);  
  -- Select PCA mode of scoring
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.svds_scoring_mode, dbms_data_mining.svds_scoring_pca);
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_shift_2dnum, dbms_data_mining.prep_shift_mean); 
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_scale_2dnum, dbms_data_mining.prep_scale_stddev);   
  -- Examples of possible overrides are:
  -- (dbms_data_mining.feat_num_features, 10);
  -- (dbms_data_mining.svds_u_matrix_output, dbms_data_mining.svds_u_matrix_enable);
  -- (dbms_data_mining.odms_approximate_computation, dbms_data_mining.odms_appr_comp_enable);
END;
/

-- Build an SVD model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'SVD_SH_sample',
    mining_function     => dbms_data_mining.feature_extraction,
    data_table_name     => 'svd_sh_sample_build_num',
    case_id_column_name => 'cust_id',
    settings_table_name => 'svd_sh_sample_settings');
END;
/

-- Display model settings
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'SVD_SH_SAMPLE'
ORDER BY setting_name;

-- Display model signature
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'SVD_SH_SAMPLE'
ORDER BY attribute_name;

-- Display model details
--

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='SVD_SH_SAMPLE'
  ORDER BY view_name;

-- The model details return the SVD decomposition matrices.
-- The user can specify the type of matrix. If no matrix type is provided
-- all stored matrices are returned.
-- In the current use case only the S matrix (singular values and variances)
-- and the V matrix (PCA bases) are stored in the model.
column value format 9999999.99
column variance format 999999999999.9
column pct_cum_variance format 999999.9
  
---- S matrix
select feature_id, VALUE, variance, pct_cum_variance 
FROM DM$VESVD_SH_SAMPLE;

---- V matrix
select feature_id, attribute_name, value
from DM$VVSVD_SH_sample
ORDER BY feature_id, attribute_name;  

-- Display the high-level model details 
column name format a30;
column string_value format 99999.99;
column string_value format a20;
SELECT name, string_value, numeric_value
FROM DM$VGSVD_SH_SAMPLE
ORDER BY name;

-- Compute the top two PCA projections that will be used for visualization
column proj1 format 9.9999999
column proj2 format 9.9999999
SELECT FEATURE_VALUE(svd_sh_sample, 1 USING *) proj1,
       FEATURE_VALUE(svd_sh_sample, 2 USING *) proj2
FROM svd_sh_sample_build_num
WHERE CUST_ID <= 101510
ORDER BY 1, 2;

-- Identify the three input attributes that most impact the top PCA projection
-- for customer 101501
set long 10000
SELECT FEATURE_DETAILS(svd_sh_sample, 1, 3 USING *) proj1det
FROM svd_sh_sample_build_num
WHERE CUST_ID = 101501;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Compression USE CASE
--
-- Goal: Compress the data and measure the reconstruction error.
-----------------------------------------------------------------------  
-- Cleanup for repeat runs
-- Cleanup old transactional table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE svd_sh_sample_build_num_piv';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old reconstruction table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE svd_sh_sample_build_num_recon';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old settings table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE svd_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old model with the same name
BEGIN DBMS_DATA_MINING.DROP_MODEL('SVD_SH_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Setting specification
-- Create settings table
set echo off
 CREATE TABLE svd_sh_sample_settings (
   setting_name  VARCHAR2(30),
   setting_value VARCHAR2(4000));
set echo on
  
-- Populate settings table
BEGIN       
  -- Select SVD as the Feature Extraction algorithm
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_singular_value_decomp);
  -- Request the output of the U matrix values (not produced by default)
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.svds_u_matrix_output, dbms_data_mining.svds_u_matrix_enable);
  INSERT INTO svd_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_off);    
  -- Examples of possible overrides are:
  -- (dbms_data_mining.feat_num_features, 10);
  -- (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
  -- (dbms_data_mining.svds_scoring_mode, dbms_data_mining.svds_scoring_pca);
  -- (dbms_data_mining.odms_approximate_computation, dbms_data_mining.odms_appr_comp_enable);
END;
/

-- Build an SVD model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'SVD_SH_sample',
    mining_function     => dbms_data_mining.feature_extraction,
    data_table_name     => 'svd_sh_sample_build_num',
    case_id_column_name => 'cust_id',
    settings_table_name => 'svd_sh_sample_settings');
END;
/

-- Display model settings
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'SVD_SH_SAMPLE'
ORDER BY setting_name;

-- Display model signature
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'SVD_SH_SAMPLE'
ORDER BY attribute_name;

-- Display model details
--
-- The model details return the SVD decomposition matrices.
-- The user can specify the type of matrix. If no matrix type is provided
-- all stored matrices are returned.
-- The S matrix represents the singular values.
-- The V and U matrices represent two new sets of orthonormal bases.
-- Usually, V is chosen as the new coordinate system and U represents
-- the projection of the data in the new coordinates.
column case_id format a10
column attribute_name format a30
column value format 9999999.99
  
---- S matrix
select feature_id, VALUE FROM DM$VESVD_SH_SAMPLE;

---- V matrix
select feature_id, attribute_name, value
from DM$VVSVD_SH_SAMPLE;  

---- U matrix
select feature_id, value 
FROM DM$VUSVD_SH_sample
WHERE case_id = 101501
ORDER BY feature_id;

-- To compress the data and reduce storage only a few of the projections
-- in the new coordinate system need to be stored.
-- In this use case, we  use only the top 5 projections. This results in
-- two-fold compression. The SVD projection values can be obtained
-- either by invoking the FEATURE_VALUE operator (see previous 
-- use case) or using the get_model_details_svd U matrix output.

-- Here, we compute the average reconstruction error due to compression.
-- To facilitate the computation, we first pivot the original data into
-- transactional format.

-- Make the data transactional
CREATE TABLE svd_sh_sample_build_num_piv as
select * from svd_sh_sample_build_num
  unpivot (value for attribute_name in("AGE", "YRS_RESIDENCE", "AFFINITY_CARD", 
  "BULK_PACK_DISKETTES", "FLAT_PANEL_MONITOR", "HOME_THEATER_PACKAGE",
  "BOOKKEEPING_APPLICATION", "PRINTER_SUPPLIES", "Y_BOX_GAMES", "OS_DOC_SET_KANJI"));


-- Compute the average reconstruction error using the top 5 projections
-- First compute the data reconstruction as U*S*V' using only the top five
-- projections.
CREATE TABLE svd_sh_sample_build_num_recon as
WITH
  s_mat AS (
  SELECT feature_id, value FROM DM$VESVD_SH_SAMPLE 
  WHERE feature_id<=5),
  v_mat AS (
  SELECT feature_id, attribute_name, value FROM DM$VVSVD_SH_SAMPLE
  WHERE feature_id<=5),
  u_mat AS (
  SELECT feature_id, case_id, value FROM DM$VUSVD_SH_SAMPLE
  WHERE feature_id<=5)
SELECT case_id cust_id, attribute_name, sum(c.value*b.VALUE*a.value) value
  FROM s_mat a, v_mat b, u_mat c
  WHERE a.feature_id=b.feature_id AND a.feature_id=c.feature_id
  GROUP BY case_id, attribute_name;

column mae format 9999999.999
-- Compute the mean absolute error.
SELECT avg(abs(a.value-b.value)) mae
FROM svd_sh_sample_build_num_recon a, svd_sh_sample_build_num_piv b
WHERE a.cust_id=b.cust_id AND a.attribute_name=b.attribute_name; 

column mape format 9999999.999
-- Compute the mean absolute percentage error.
SELECT avg(abs((a.value-b.value)/
                CASE WHEN b.VALUE=0 THEN 1 ELSE b.VALUE END)) mape
FROM svd_sh_sample_build_num_recon a, svd_sh_sample_build_num_piv b
WHERE a.cust_id=b.cust_id AND a.attribute_name=b.attribute_name; 

-----------------------------------------------------------------------
--    BUILD and APPLY a transient model using analytic functions
-----------------------------------------------------------------------
-- In addition to creating a persistent model that is stored as a schema
-- object, models can be built and scored on data on the fly using
-- Oracle's analytic function syntax.

--------------------
-- BUSINESS USE CASE
-- 
-- Map customer attributes into six features and return the feature
-- mapping for customer 100001.
-- All data in the apply view is used to construct the feature mappings.
-- All necessary data preparation steps are automatically performed.
column feature_id format 999
column value format 999.999
select feature_id, value 
from (
 select cust_id, feature_set(into 6 using *) over () fset
 from mining_data_apply_v),
table(fset)
where cust_id = 100001
order by feature_id;
