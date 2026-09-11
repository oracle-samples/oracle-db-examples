-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   Classification - SVM Algorithm with Text Mining - dmtxtsvm.sql  
--   Copyright (c) 2026 Oracle Corporation and/or its affiliates.
--
--   The Universal Permissive License (UPL), Version 1.0
--   https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-- Create a policy for text feature extraction

BEGIN
  ctx_ddl.drop_policy('dmdemo_svm_policy');
  EXCEPTION WHEN OTHERS THEN NULL; END;
/

EXECUTE ctx_ddl.create_policy('dmdemo_svm_policy');

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------

-- Mine text features using SVM algorithm. 

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model and objects for repeat runs

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE t_svmc_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

 

---------------
-- CREATE MODEL

-- Create SVM model
-- Note that the transform treats the 'comments' attribute
-- as unstructured text data


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('T_SVM_Clas_sample');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', null, 'TEXT');
  v_setlst(dbms_data_mining.algo_name) := dbms_data_mining.algo_support_vector_machines;
  v_setlst(dbms_data_mining.prep_auto) := dbms_data_mining.prep_auto_on;
  v_setlst(dbms_data_mining.svms_kernel_function) := dbms_data_mining.svms_linear;
  v_setlst(dbms_data_mining.svms_complexity_factor) := '100';
  v_setlst(dbms_data_mining.odms_text_policy_name) := 'DMDEMO_SVM_POLICY';
  v_setlst(dbms_data_mining.svms_solver) := dbms_data_mining.svms_solver_sgd;
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'T_SVM_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_query          => 'SELECT * FROM mining_build_text',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
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
  EXECUTE IMMEDIATE 'DROP TABLE t_svmc_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('T_SVM_Clas_sample');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE t_svmc_sample_settings (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO t_svmc_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_support_vector_machines);
    INSERT INTO t_svmc_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
    INSERT INTO t_svmc_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.svms_kernel_function, dbms_data_mining.svms_linear);
    INSERT INTO t_svmc_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.svms_complexity_factor, 100);
    INSERT INTO t_svmc_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.odms_text_policy_name, 'DMDEMO_SVM_POLICY');
    INSERT INTO t_svmc_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.svms_solver, dbms_data_mining.svms_solver_sgd);
END;
/
DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'comments', null, 'comments', null, 'TEXT');
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name => 'T_SVM_Clas_sample',
      mining_function => dbms_data_mining.classification,
      data_table_name => 'mining_build_text',
      case_id_column_name => 'cust_id',
      target_column_name => 'affinity_card',
      settings_table_name => 't_svmc_sample_settings',
      xform_list => xformlist);
END;
/
 
-- Display the model settings

column setting_name format a30;
column setting_value format a30;

SELECT setting_name, setting_value
FROM user_mining_model_settings
WHERE model_name = 'T_SVM_CLAS_SAMPLE'
ORDER BY setting_name;

-- Display the model signature

column attribute_name format a40
column attribute_type format a20

SELECT attribute_name, attribute_type
FROM user_mining_model_attributes
WHERE model_name = 'T_SVM_CLAS_SAMPLE'
ORDER BY attribute_name;

-- Display model details
-- Get a list of model views

col view_name format a30
col view_type format a50

SELECT view_name, view_type FROM user_mining_model_views
WHERE model_name='T_SVM_CLAS_SAMPLE'
ORDER BY view_name;

-- Note how several text terms extracted from the COMMENTs documents
-- show up as influential predictors.
--

SET line 120
column attribute_name format a25
column attribute_subname format a25
column attribute_value format a25
column coefficient format 9.99

SELECT * FROM 
(SELECT target_value, attribute_name, attribute_subname, 
        attribute_value, coefficient,
        rank() OVER (ORDER BY abs(coefficient) DESC) rnk
FROM DM$VLT_SVM_CLAS_SAMPLE)
WHERE rnk <= 10
ORDER BY rnk, attribute_name, attribute_subname;


-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

-- See dmsvcdem.sql for examples.

-----------------------------------------------------------------------
--                SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
-----------------------------------------------------------------------

------------------
-- BUSINESS CASE 1
------------------

-- Find the 5 customers that are most likely to use an affinity card.
-- Note that the SQL data mining functions seamless work against
-- tables that contain textual data (comments).
-- Also explain why they are likely to use an affinity card.
--

set long 20000

SELECT cust_id, pd FROM
( SELECT cust_id, 
    PREDICTION_DETAILS(T_SVM_Clas_sample, 1 USING *) pd,
    rank() OVER (ORDER BY PREDICTION_PROBABILITY(T_SVM_Clas_sample, 1 USING *) DESC, 
                          cust_id) rnk
FROM mining_apply_text)
WHERE rnk <= 5
ORDER BY rnk;

------------------
-- BUSINESS CASE 2
------------------

-- Find the average age of customers who are likely to use an
-- affinity card. Break out the results by gender.
--

column cust_gender format a12

SELECT cust_gender,
       COUNT(*) AS cnt,
       ROUND(AVG(age)) AS avg_age
FROM mining_apply_text
WHERE PREDICTION(T_SVM_Clas_sample USING *) = 1
GROUP BY cust_gender
ORDER BY cust_gender;

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('T_SVM_CLAS_SAMPLE');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE T_SVMC_SAMPLE_SETTINGS';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
