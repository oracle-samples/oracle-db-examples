-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 23ai
--
--   Feature Extraction - ESA Algorithm for Text Mining
--
--   Copyright (c) 2024 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

-----------------------------------------------------------------------
--                            Prerequisites
-----------------------------------------------------------------------

-- Install the Wiki ESA model
--   https://oss.oracle.com/machine-learning/
-- Run the dmsh.sql script 
--   https://github.com/oracle-samples/oracle-db-examples/blob/main/machine-learning/sql/23ai/dmsh.sql

-----------------------------------------------------------------------
--                            EXAMPLES IN THIS SCRIPT
-----------------------------------------------------------------------
-- Create an ESA model with CREATE_MODEL PL/SQL procedure, which uses a
-- separate settings table as input. 

-- Walk thorugh 3 ESA use cases with the model

-- Create an ESA model with CREATE_MODEL2, which provides settings
-- as part of the procedure. 

-- (23ai Feature) Create an ESA model with dense projections, which is  
-- similar to a doc2vec approach, by specifying the ESAS_EMBEDDINGS 
-- parameter as ESAS_EMBEDDINGS_ENABLED.

-- (23ai Feature) Use the dense projection scoring results to create a  
-- clustering model. You can use such projections to improve the quality  
-- of, e.g., classification and clustering models - a common use case 
-- for dense projections.
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
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------
-- Create a policy for text feature extraction
-- The policy will include stemming
BEGIN ctx_ddl.drop_policy('dmdemo_esa_policy');
EXCEPTION when others then null; END;
/
BEGIN ctx_ddl.drop_preference('dmdemo_esa_lexer');
EXCEPTION when others then null; END;
/
BEGIN
  ctx_ddl.create_preference('dmdemo_esa_lexer', 'BASIC_LEXER');
  ctx_ddl.set_attribute('dmdemo_esa_lexer', 'index_stems', 'ENGLISH');
--  ctx_ddl.set_attribute('dmdemo_esa_lexer', 'index_themes', 'YES');
END;
/
BEGIN
  ctx_ddl.create_policy('dmdemo_esa_policy', lexer=>'dmdemo_esa_lexer');
END;
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
CREATE OR REPLACE VIEW mining_build_text_parallel AS
  SELECT /*+ parallel (4)*/ min(cust_id) as cust_id, comments
  FROM   mining_build_text
  WHERE  length(comments) >= 70
  GROUP BY comments;

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
     -- 'TEXT(POLICY_NAME:DMDEMO_ESA_POLICY)(TOKEN_TYPE:STEM)');
    'TEXT(POLICY_NAME:DMDEMO_ESA_POLICY)(TOKEN_TYPE:THEME)');

  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'ESA_text_sample',
    mining_function     => dbms_data_mining.feature_extraction,
    data_table_name     => 'mining_build_text_parallel',
    case_id_column_name => 'cust_id',
    settings_table_name => 'ESA_text_sample_settings',
    xform_list          => xformlist);
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30;
column setting_value format a30;
column setting_type format a10;

SELECT setting_name, setting_value, setting_type AS type
FROM   user_mining_model_settings
WHERE  model_name = 'ESA_TEXT_SAMPLE'
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

SELECT view_name, view_type
FROM   user_mining_model_views
WHERE  model_name='ESA_TEXT_SAMPLE'
ORDER BY view_name;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
--
-- Unlike other feature extraction functions, ESA does not discover new features. 
-- It treats the rows of the training data as predefined features. 
-- Test data are expressed via these pre-defined features as a basis.
--

-------------------------------------------------
-- SCORE NEW DATA USING SQL FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the customer comments (features) most relevant to the input text.
-- The comments are sorted according to their relevancy.
--
column value format 9.99999
column comments format a200

SELECT cust_id, 
       1-feature_compare(ESA_TEXT_SAMPLE 
                         using 'card discount' comments AND
                         using comments) similarity,
       comments 
FROM   mining_build_text_parallel
ORDER BY similarity desc;

-- Another similar example
SELECT cust_id, 
       1-feature_compare(ESA_TEXT_SAMPLE 
                         using 'computer manual' comments AND
                         using comments) similarity,
       comments 
FROM mining_build_text_parallel
ORDER BY similarity DESC

-- Another example with longer text
-- The input is the following comment

SELECT comments
FROM   mining_test_text_parallel
WHERE  cust_id = 103030;

-- the most relevant comments from build data
SELECT s.value, m.comments
FROM   (SELECT feature_set(ESA_TEXT_SAMPLE, 5 using *) fset
        FROM (SELECT comments FROM mining_test_text_parallel
              WHERE cust_id = 103030)) t,
       TABLE(t.fset) s, 
       mining_build_text_parallel m
WHERE  s.feature_id = m.cust_id
ORDER BY s.value desc;

------------------
-- BUSINESS CASE 2
-- List the attributes that represent customer comments (cust_id=101613).
-- The attributes are sorted according to their coefficients.
--
column coefficient format 9.99999
column attribute_subname format a30

-- comments for cust_id=101613
SELECT comments 
FROM   mining_build_text_parallel 
WHERE  cust_id = 101613;

-- attributes representing the comments in the model
SELECT attribute_subname, coefficient
FROM   dm$vaESA_TEXT_SAMPLE
WHERE  feature_id = 101613
ORDER BY coefficient desc;

------------------
-- BUSINESS CASE 3
-- Compare customer comments using the model
--
-- create a test data view with case ID and text column
CREATE OR REPLACE VIEW mining_test_text_only AS
SELECT cust_id, comments 
FROM   mining_test_text_parallel
WHERE  cust_id < 103005;

column comments format a50
-- test data
SELECT cust_id, comments
FROM mining_test_text_only
ORDER BY cust_id;

-- test data relatedness based on the model
-- smaller values correspond to more related data rows

column comp format 9.99999

SELECT a.cust_id id1, b.cust_id id2,
       feature_compare(ESA_TEXT_SAMPLE using a.comments and using b.comments) comp
FROM  mining_test_text_only a, mining_test_text_only b
WHERE a.cust_id < b.cust_id
ORDER BY comp;

-----------------------------------------------------------------------
--                         CREATE MODEL WITH CREATE_MODEL2
-----------------------------------------------------------------------
-- This improves on the CREATE_MODEL procedure by allowing you to use a query
-- rather than a database table as input. You also no longer need to declare
-- and populate a settings table.
-- Other than using CREATE_MODEL2, this model is identical to the first one.

-- Cleanup old model and objects for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('ESA_text_sample2');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
  v_setlst  DBMS_DATA_MINING.SETTING_LIST;

BEGIN
  v_setlst('PREP_AUTO')               := 'ON';
  v_setlst('ALGO_NAME')               := 'ALGO_EXPLICIT_SEMANTIC_ANALYS';
  v_setlst('ODMS_TEXT_POLICY_NAME')   := 'DMDEMO_ESA_POLICY';
  v_setlst('ESAS_MIN_ITEMS')          := '5';
  v_setlst('ODMS_TEXT_MIN_DOCUMENTS') := '2';

  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', 'comments',
      'TEXT(POLICY_NAME:DMDEMO_ESA_POLICY)(TOKEN_TYPE:STEM)');

  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'ESA_text_sample2',
    mining_function     => 'FEATURE_EXTRACTION',
    data_query          => 'SELECT * FROM mining_build_text_parallel',
    case_id_column_name => 'cust_id',
    set_list            => v_setlst,
    xform_list          => xformlist);
END;
/

-------------------------
-- Score using the model

column value format 9.99999
column comments format a200

SELECT s.feature_id, s.value 
FROM 
  (SELECT cust_id, comments, feature_set(ESA_TEXT_SAMPLE2, 5 using comments) fset 
   FROM   mining_build_text_parallel) t,
          TABLE(t.fset) s
ORDER BY s.value desc;


-----------------------------------------------------------------------
--                    CREATE MODEL WITH DENSE PROJECTIONS
-----------------------------------------------------------------------
-- Create another model with CREATE_MODEL2, this time specifying the
-- ESAS_EMBEDDINGS parameter and setting it to ESAS_EMBEDDINGS_ENABLE.
-- Doing so means that scoring this model will produce dense projections with
-- embeddings, similar to a doc2vec approach.

BEGIN DBMS_DATA_MINING.DROP_MODEL('ESA_text_sample_dense');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
  v_setlst  DBMS_DATA_MINING.SETTING_LIST;

BEGIN
  v_setlst('PREP_AUTO')               := 'ON';
  v_setlst('ALGO_NAME')               := 'ALGO_EXPLICIT_SEMANTIC_ANALYS';
  v_setlst('ODMS_TEXT_POLICY_NAME')   := 'DMDEMO_ESA_POLICY';
  v_setlst('ESAS_MIN_ITEMS')          := '5';
  v_setlst('ODMS_TEXT_MIN_DOCUMENTS') := '2';
  v_setlst('ESAS_EMBEDDINGS')         := 'ESAS_EMBEDDINGS_ENABLE';
  v_setlst('ESAS_EMBEDDING_SIZE')     := '1024';

  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', 'comments',
      'TEXT(POLICY_NAME:DMDEMO_ESA_POLICY)(TOKEN_TYPE:STEM)');

  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'ESA_text_sample_dense',
    mining_function     => 'FEATURE_EXTRACTION',
    data_query          => 'SELECT * FROM mining_build_text_parallel',
    case_id_column_name => 'cust_id',
    set_list            => v_setlst,
    xform_list          => xformlist);
END;
/


-------------------------
-- DISPLAY MODEL SETTINGS
-- Note the ESAS_EMBEDDINGS and ESAS_EMBEDDINGS_SIZE settings.
--
column setting_name format a30;
column setting_value format a30;
column setting_type format a10;

SELECT setting_name, setting_value, setting_type AS type
FROM   user_mining_model_settings
WHERE  model_name = 'ESA_TEXT_SAMPLE_DENSE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a30
column attribute_type format a20
column data_type format a20

SELECT attribute_name, attribute_type, data_type
FROM   user_mining_model_attributes
WHERE  model_name='ESA_TEXT_SAMPLE_DENSE'
ORDER BY attribute_name;

--------------------------
-- Get a list of model views
--
col view_name format a30
col view_type format a50

SELECT view_name, view_type
FROM   user_mining_model_views
WHERE  model_name='ESA_TEXT_SAMPLE_DENSE'
ORDER BY view_name;

-------------------------
-- STORE SCORING RESULTS IN TABLE
--

BEGIN EXECUTE IMMEDIATE 'DROP TABLE esa_dense_results';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
column value format 9.99999
column comments format a200

CREATE TABLE esa_dense_results AS
SELECT cust_id, s.feature_id, s.value, comments 
FROM   (SELECT cust_id, comments,
               feature_set(ESA_TEXT_SAMPLE_DENSE using comments) fset 
        FROM   mining_build_text_parallel) t,
       TABLE(t.fset) s;

-----------------------------------------------------------------------
--              PASS PROJECTIONS INTO CLUSTERING MODEL
-----------------------------------------------------------------------
-- A common use case for the dense projections created by the scoring results
-- of the model above is to use them to train other models, such as
-- classification or clustering. The expectation is that the addition of these
-- results may improve model accuracy.
-- Here we create a clustering model using the dense projections.

-------------------------
-- Prepare ESA dense results to create clustering model
--

CREATE OR REPLACE VIEW esa_dense_results_v AS
  SELECT cust_id, 
         comments,
         CAST(COLLECT(dm_nested_numerical(feature_id, value))
            AS dm_nested_numericals) AS nest
  FROM esa_dense_results
  GROUP BY cust_id, comments;

---------------------------
-- CREATE CLUSTERING MODEL
-- Use the table augmented with the dense projection to create a
-- clustering model

BEGIN DBMS_DATA_MINING.DROP_MODEL('CLUSTERING_EXAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
  xformlist DBMS_DATA_MINING_TRANSFORM.TRANSFORM_LIST;
  v_setlst  DBMS_DATA_MINING.SETTING_LIST;

BEGIN
  v_setlst('PREP_AUTO')    := 'ON';
  v_setlst('ALGO_NAME')    := 'ALGO_KMEANS';
  v_setlst('KMNS_DETAILS') := 'KMNS_DETAILS_HIERARCHY';

  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'CLUSTERING_EXAMPLE',
    mining_function     => 'CLUSTERING',
    data_query          => 'SELECT * FROM esa_dense_results_v',
    case_id_column_name => 'cust_id',
    set_list =>v_setlst);
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30

SELECT setting_name, setting_value
FROM   user_mining_model_settings
WHERE  model_name = 'CLUSTERING_EXAMPLE'
ORDER BY setting_name;

-- Get a list of model views
col view_name format a30
col view_type format a50

SELECT view_name, view_type
FROM   user_mining_model_views
WHERE  model_name='CLUSTERING_EXAMPLE'
ORDER BY view_name;

-- CLUSTERS
-- For each cluster_id, provide the number of records in the cluster,
-- the parent cluster id, the level in the hierarchy, and dispersion,
-- which is a measure of individual cluster quality, and computationally,
-- the sum of square errors.
--
SELECT cluster_id CLU_ID, RECORD_COUNT REC_CNT, parent, TREE_LEVEL,
       ROUND(TO_NUMBER(dispersion),3) dispersion
FROM   DM$VDCLUSTERING_EXAMPLE
ORDER BY CLUSTER_ID;

SELECT CLUSTER_ID CLU_ID, RECORD_COUNT REC_CNT, ROUND(TO_NUMBER(dispersion),3) DISPERSION
FROM   DM$VDCLUSTERING_EXAMPLE
WHERE  LEFT_CHILD_ID IS NULL AND RIGHT_CHILD_ID IS NULL
ORDER BY CLUSTER_ID;

-----------------------------------------------------------------------
--   End of script
-----------------------------------------------------------------------
