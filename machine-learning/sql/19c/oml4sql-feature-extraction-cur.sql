-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 19c
-- 
--   Feature and Row Extraction - CUR Decomposition Algorithm - dmcurdemo.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
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
-- Perform CUR decomposition-based attribute and row importance for:
-- Selecting top attributes and rows with highest importance scores
-- (Select approximately top 10 attributes and top 50 rows)
--

-- Cleanup for repeat runs
-- Cleanup old settings table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE cur_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old model with the same name
BEGIN DBMS_DATA_MINING.DROP_MODEL('CUR_SH_SAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Setting specification
-- Create settings table
CREATE TABLE cur_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

-- Populate settings table
BEGIN
  -- Select CUR Decomposition as the Attribute Importance algorithm
  INSERT INTO cur_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_cur_decomposition);
  -- Set row importance to be enabled (disabled by default)
  INSERT INTO cur_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.curs_row_importance, dbms_data_mining.curs_row_imp_enable);
  -- Set approximate number of attributes to be selected
  INSERT INTO cur_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.curs_approx_attr_num, '10');
  -- Set approximate number of rows to be selected
  INSERT INTO cur_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.curs_approx_row_num, '50');
  -- Set SVD rank parameter
  INSERT INTO cur_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.curs_svd_rank, '5');
  -- Examples of possible overrides are:
  -- (dbms_data_mining.odms_random_seed, '1');  
END;
/

-- Build a CUR model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'CUR_SH_SAMPLE',
    mining_function     => dbms_data_mining.attribute_importance,
    data_table_name     => 'MINING_DATA_BUILD_V',
    case_id_column_name => 'cust_id',
    settings_table_name => 'cur_sh_sample_settings');
END;
/

-- Display model settings
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'CUR_SH_SAMPLE'
ORDER BY setting_name;

-- Display model signature
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'CUR_SH_SAMPLE'
ORDER BY attribute_name;

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='CUR_SH_SAMPLE'
  ORDER BY view_name;

-- Display global model details
column name format a30
column numeric_value format 9999999999
SELECT name, numeric_value
  FROM DM$VGCUR_SH_SAMPLE
ORDER BY name;

-- Attribute importance and ranks
column attribute_name format a15
column attribute_subname format a18
column attribute_value format a15
column attribute_importance format 9.99999999
column attribute_rank format 999999

SELECT attribute_name, attribute_subname, attribute_value, 
       attribute_importance, attribute_rank
FROM   DM$VCCUR_SH_SAMPLE
ORDER BY attribute_rank, attribute_name, attribute_subname,
         attribute_value;

-- Row importance and ranks
column case_id format 999999999
column row_importance format 9.99999999
column row_rank format 999999999

SELECT case_id, row_importance, row_rank
  FROM DM$VRCUR_SH_SAMPLE
ORDER BY row_rank, case_id;
