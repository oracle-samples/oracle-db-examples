-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   Feature Extraction - ESA Algorithm for Text Mining - dmtxtesa.sql
--   
--   Copyright (c) 2019 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------  

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

SET serveroutput ON
SET pages 10000

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Mine text features using ESA algorithm. 

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------
-- Create a policy for text feature extraction
-- The policy will include stemming
begin
  ctx_ddl.drop_policy('dmdemo_esa_policy');
exception when others then null;
end;
/
begin
  ctx_ddl.drop_preference('dmdemo_esa_lexer');
exception when others then null;
end;
/
begin
  ctx_ddl.create_preference('dmdemo_esa_lexer', 'BASIC_LEXER');
  ctx_ddl.set_attribute('dmdemo_esa_lexer', 'index_stems', 'ENGLISH');
--  ctx_ddl.set_attribute('dmdemo_esa_lexer', 'index_themes', 'YES');
end;
/
begin
  ctx_ddl.create_policy('dmdemo_esa_policy', lexer=>'dmdemo_esa_lexer');
end;
/

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model and objects for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('ESA_text_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ESA_text_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create a build data view with case ID and text column
CREATE OR REPLACE VIEW mining_build_text_only AS
  (SELECT min(cust_id) cust_id, comments 
  FROM mining_build_text WHERE length(comments) >= 70 group by comments);

--------------------------------------------------------------------------------
--
-- Create view mining_build_text_parallel with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW mining_build_text_parallel AS SELECT /*+ parallel (4)*/ * FROM mining_build_text_only;

-- Create settings table to choose text policy and auto data prep
CREATE TABLE ESA_text_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
 
BEGIN
  -- Populate settings table
  INSERT INTO ESA_text_sample_settings VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_explicit_semantic_analys);
  INSERT INTO ESA_text_sample_settings VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
  INSERT INTO ESA_text_sample_settings VALUES
    (dbms_data_mining.odms_text_policy_name, 'DMDEMO_ESA_POLICY');
  -- lower than the default value of 100 due to the small size of data
  INSERT INTO ESA_text_sample_settings VALUES 
    ('ESAS_MIN_ITEMS', 5);
  -- lower than the default value of 3 due to the small size of data
  INSERT INTO ESA_text_sample_settings VALUES
    ('ODMS_TEXT_MIN_DOCUMENTS', 2);
--('ODMS_TEXT_MAX_FEATURES', 10000); 
--('ESAS_TOPN_FEATURES', 500);
--('ESAS_VALUE_THRESHOLD', 0.0001);
  COMMIT;
END;
/

---------------------
-- CREATE A NEW MODEL
-- Note that the transform makes the column 'comments'  
-- to be treated as unstructured text data
--
DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', 'comments', 
      'TEXT(POLICY_NAME:DMDEMO_ESA_POLICY)(TOKEN_TYPE:STEM)');
-- 'TEXT(POLICY_NAME:DMDEMO_ESA_POLICY)(TOKEN_TYPE:THEME)');
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name => 'ESA_text_sample',
    mining_function => dbms_data_mining.feature_extraction,
    data_table_name => 'mining_build_text_parallel',
    case_id_column_name => 'cust_id',
    settings_table_name => 'ESA_text_sample_settings',
    xform_list => xformlist);
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30;
column setting_value format a30;
column setting_type format a10;
SELECT setting_name, setting_value, setting_type as type
  FROM user_mining_model_settings
 WHERE model_name = 'ESA_TEXT_SAMPLE'
ORDER BY setting_name; 

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a30
column attribute_type format a20
column data_type format a20
SELECT attribute_name, attribute_type, data_type
FROM   user_mining_model_attributes
WHERE  model_name='ESA_TEXT_SAMPLE'
ORDER BY attribute_name;


-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
WHERE model_name='ESA_TEXT_SAMPLE'
ORDER BY view_name;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
--
-- Unlike other feature extraction functions, the Explicit Semantic Analysis 
-- does not discover new features. It treats the rows of the training data 
-- as pre-defined features. Test data are expressed via these pre-defined 
-- features as a basis.
-- 

-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the customer comments (features) that are most relevant to the input text.
-- The comments are sorted according to their relevancy.
-- 
column value format 9.99999
column comments format a200
select s.value, m.comments from
  (select feature_set(ESA_TEXT_SAMPLE, 5 using *) fset from 
  (SELECT 'card discount' AS comments FROM dual)) t,
table(t.fset) s, mining_build_text_parallel m
where s.feature_id = m.cust_id order by s.value desc;

-- One more similar example
select s.value, m.comments from
  (select feature_set(ESA_TEXT_SAMPLE, 5 using *) fset from 
  (SELECT 'computer manual' AS comments FROM dual)) t,
table(t.fset) s, mining_build_text_parallel m
where s.feature_id = m.cust_id order by s.value desc;

-- Yet another example with longer text
-- The input is the following comments
SELECT comments FROM mining_test_text_parallel where cust_id = 103030;
-- the most relevant comments from build data
select s.value, m.comments from
  (select feature_set(ESA_TEXT_SAMPLE, 5 using *) fset from 
  (SELECT comments FROM mining_test_text_parallel where cust_id = 103030)) t,
table(t.fset) s, mining_build_text_parallel m
where s.feature_id = m.cust_id order by s.value desc;

------------------
-- BUSINESS CASE 2
-- List the attributes that represent customer comments (cust_id=101613).
-- The attributes are sorted according to their coefficients.
--
column coefficient format 9.99999
column attribute_subname format a30
-- comments for cust_id=101613
select comments FROM mining_build_text_parallel where cust_id = 101613;
-- attributes representing the comments in the model
select attribute_subname, coefficient from dm$vaESA_TEXT_SAMPLE
  where feature_id = 101613 order by coefficient desc;

------------------
-- BUSINESS CASE 3
-- Compare customer comments using the model
-- 
-- create a test data view with case ID and text column
CREATE OR REPLACE VIEW mining_test_text_only AS
  (SELECT min(cust_id) cust_id, comments FROM mining_test_text_parallel 
  where cust_id < 103005 group by comments);

column comments format a50
-- test data
SELECT cust_id, comments from mining_test_text_only order by cust_id;
-- test data relatedness based on the model
-- smaller values correspond to more related data rows
column comp format 9.99999
select a.cust_id id1, b.cust_id id2,
  feature_compare(ESA_TEXT_SAMPLE using a.comments and using b.comments) comp
from mining_test_text_only a, mining_test_text_only b
where a.cust_id < b.cust_id order by comp;
