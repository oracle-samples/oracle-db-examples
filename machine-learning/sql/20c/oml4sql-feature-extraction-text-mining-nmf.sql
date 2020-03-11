-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   Feature Extraction - NMF Algorithm with Text Mining - dmtxtnmf.sql
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
-- Mine text features using NMF algorithm. 

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------
-- Create a policy for text feature extraction
-- The policy will include stemming
begin
  ctx_ddl.drop_policy('dmdemo_nmf_policy');
exception when others then null;
end;
/
begin
  ctx_ddl.drop_preference('dmdemo_nmf_lexer');
exception when others then null;
end;
/
begin
  ctx_ddl.create_preference('dmdemo_nmf_lexer', 'BASIC_LEXER');
  ctx_ddl.set_attribute('dmdemo_nmf_lexer', 'index_stems', 'ENGLISH');
--  ctx_ddl.set_attribute('dmdemo_nmf_lexer', 'index_themes', 'YES');
end;
/
begin
  ctx_ddl.create_policy('dmdemo_nmf_policy', lexer=>'dmdemo_nmf_lexer');
end;
/

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model and objects for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('T_NMF_Sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE t_nmf_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------------------------------
-- CREATE A NEW MODEL USING SETTINGS TABLE
-- Note the transform makes the 'comments' attribute 
-- to be treated as unstructured text data
--

-- Create settings table to choose text policy and auto data prep
CREATE TABLE t_nmf_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
 
BEGIN
  -- Populate settings table
  INSERT INTO t_nmf_sample_settings VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
  INSERT INTO t_nmf_sample_settings VALUES(
    dbms_data_mining.odms_text_policy_name, 'DMDEMO_NMF_POLICY');
--(dbms_data_mining.nmfs_conv_tolerance,0.05);
--(dbms_data_mining.nmfs_num_iterations,50);
--(dbms_data_mining.nmfs_random_seed,-1);
--(dbms_data_mining.nmfs_stop_criteria,dbms_data_mining.nmfs_sc_iter_or_conv);
  COMMIT;
END;
/

DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', null, 'TEXT(TOKEN_TYPE:STEM)');
--    xformlist, 'comments', null, 'comments', null, 'TEXT(TOKEN_TYPE:THEME)');
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name => 'T_NMF_Sample',
    mining_function => dbms_data_mining.feature_extraction,
    data_table_name => 'mining_build_text',
    case_id_column_name => 'cust_id',
    settings_table_name => 't_nmf_sample_settings',
    xform_list => xformlist);
END;
/
    
--------------------------------------------------------
-- CREATE A NEW MODEL USING V_SETLST (NO SETTINGS TABLE)
-- Note the transform makes the 'comments' attribute 
-- to be treated as unstructured text data
--
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
    dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', null, 'TEXT(TOKEN_TYPE:STEM)');
--    xformlist, 'comments', null, 'comments', null, 'TEXT(TOKEN_TYPE:THEME)');

    v_setlst('PREP_AUTO') := 'ON';
    v_setlst('ALGO_NAME') := 'ALGO_NMF';
    V_setlst('odms_text_policy_name' := 'DMDEMO_NMF_POLICY';
    DBMS_DATA_MINING.CREATE_MODEL2(
        'T_NMF_Sample',
        'FEATURE_EXTRACTION',
        'SELECT * FROM mining_build_text',
        v_setlst,
        'cust_id',
        'AFFINITY_CARD');
END;

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30;
column setting_value format a30;
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'T_NMF_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'T_NMF_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
WHERE model_name='T_NMF_SAMPLE'
ORDER BY view_name;

column attribute_name format a30;
column attribute_value format a20;
column coefficient format 9.99999;
set pages 15;
SET line 120;
break ON feature_id;
SELECT * FROM (
SELECT feature_id,
       nvl2(attribute_subname,
            attribute_name||'.'||attribute_subname,
            attribute_name) attribute_name,
       attribute_value,
       coefficient
  FROM DM$VET_NMF_SAMPLE
WHERE feature_id < 3
ORDER BY 1,2,3,4)
WHERE ROWNUM < 21;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-- See dmnmdemo.sql for examples.
