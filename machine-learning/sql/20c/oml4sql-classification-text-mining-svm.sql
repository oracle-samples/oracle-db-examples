-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   Classification - SVM Algorithm with Text Mining - dmtxtsvm.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
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
BEGIN DBMS_DATA_MINING.DROP_MODEL('T_SVM_Clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE t_svmc_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create settings table to choose linear kernel
CREATE TABLE t_svmc_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
 
BEGIN
  -- Populate settings table
  INSERT INTO t_svmc_sample_settings VALUES
    (dbms_data_mining.algo_name,
     dbms_data_mining.algo_support_vector_machines);
  INSERT INTO t_svmc_sample_settings VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
  INSERT INTO t_svmc_sample_settings VALUES
    (dbms_data_mining.svms_kernel_function,dbms_data_mining.svms_linear);
  INSERT INTO t_svmc_sample_settings VALUES
    (dbms_data_mining.svms_complexity_factor, 100);
  INSERT INTO t_svmc_sample_settings VALUES
    (dbms_data_mining.odms_text_policy_name, 'DMDEMO_SVM_POLICY');
  INSERT INTO t_svmc_sample_settings VALUES
    (dbms_data_mining.svms_solver, dbms_data_mining.svms_solver_sgd);
  COMMIT;
END;
/

---------------
-- CREATE MODEL

-- Create SVM model
-- Note the transform makes the 'comments' attribute 
-- to be treated as unstructured text data
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
SELECT * from 
(SELECT target_value, attribute_name, attribute_subname, 
        attribute_value, coefficient,
        rank() over (order by abs(coefficient) desc) rnk
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
--
-- Find the 5 customers that are most likely to use an affinity card.
-- Note that the SQL data mining functions seamless work against
-- tables that contain textual data (comments).
-- Also explain why they are likely to use an affinity card.
--
set long 20000
SELECT cust_id, pd FROM
( SELECT cust_id, 
    PREDICTION_DETAILS(T_SVM_Clas_sample, 1 USING *) pd,
    rank() over (order by PREDICTION_PROBABILITY(T_SVM_Clas_sample, 1 USING *) DESC, 
                          cust_id) rnk
  FROM mining_apply_text)
WHERE rnk <= 5
order by rnk;

------------------
-- BUSINESS CASE 2
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
