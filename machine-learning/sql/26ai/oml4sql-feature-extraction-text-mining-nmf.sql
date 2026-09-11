-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   Feature Extraction - NMF Algorithm with Text Mining - dmtxtnmf.sql  
--   Copyright (c) 2026 Oracle Corporation and/or its affiliates.
--
--   The Universal Permissive License (UPL), Version 1.0
--   https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

  
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

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE t_nmf_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-------------------------------------------
-- CREATE A NEW MODEL USING SETTINGS TABLE
-- Note that the transform treats the 'comments' attribute
-- as unstructured text data
--

 


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('T_NMF_Sample');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', null, 'TEXT(TOKEN_TYPE:STEM)');
--    xformlist, 'comments', null, 'comments', null, 'TEXT(TOKEN_TYPE:THEME)');
  v_setlst(dbms_data_mining.prep_auto) := dbms_data_mining.prep_auto_on;
  v_setlst(dbms_data_mining.odms_text_policy_name) := 'DMDEMO_NMF_POLICY';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'T_NMF_Sample',
    mining_function     => dbms_data_mining.feature_extraction,
    data_query          => 'SELECT * FROM mining_build_text',
    case_id_column_name => 'cust_id',
    set_list            => v_setlst,
    xform_list          => xformlist
    );
END;
/

-----------------------------------------------------------------------
-- CREATE_MODEL EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL is useful for application development when model settings
-- are separated into a settings table for convenient updating.
-- This build intentionally replaces the model created by the preceding CREATE_MODEL2 example.

-- Drop settings table if it exists
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE t_nmf_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('T_NMF_Sample');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE t_nmf_sample_settings (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO t_nmf_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
    INSERT INTO t_nmf_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.odms_text_policy_name, 'DMDEMO_NMF_POLICY');
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

-------------------------
-- DISPLAY MODEL SETTINGS
-------------------------

column setting_name format a30;
column setting_value format a30;

SELECT setting_name, setting_value
FROM user_mining_model_settings
WHERE model_name = 'T_NMF_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--------------------------

column attribute_name format a40
column attribute_type format a20

SELECT attribute_name, attribute_type
FROM user_mining_model_attributes
WHERE model_name = 'T_NMF_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
------------------------


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

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('T_NMF_SAMPLE');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE T_NMF_SAMPLE_SETTINGS';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
