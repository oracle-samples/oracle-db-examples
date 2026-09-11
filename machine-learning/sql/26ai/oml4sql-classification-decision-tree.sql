-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   Classification - Decision Tree Algorithm - dmdtdemo.sql  
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
SET linesize 420
SET echo ON
SET long 2000000000

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------

-- Given demographic data about a set of customers, predict the
-- customer response to an affinity card program using a classifier
-- based on Decision Trees algorithm.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_parallel_v (build data)
-- mining_data_test_parallel_v  (test data)
-- mining_data_apply_parallel_v (apply data)
-- (See dmsh.sql for view definitions).

-----------
-- ANALYSIS
-----------

-- These are the factors to consider for data analysis in decision trees:
-----------

-- 1. Missing Value Treatment for Predictors
--

--    See dmsvcdem.sql for a definition of missing values, and the
--    steps to be taken for missing value imputation.
--

--    Decision Tree implementation in OML4SQL handles missing predictor
--    values (by penalizing predictors which have missing values)
--    and missing target values (by simply discarding records with
--    missing target values).
--

-- 2. Outlier Treatment for Predictors for Build data
--

--    See dmsvcdem.sql for a discussion on outlier treatment.
--    For OML4SQL decision trees, outlier treatment is not really necessary.
--

-- 3. Binning high cardinality data
--    No data preparation for the types we accept is necessary - even
--    for high cardinality predictors.  Preprocessing to reduce the
--    cardinality (e.g., binning) can improve the performance of the build.
--

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------


--------------------------------
-- PREPARE BUILD (TRAINING) DATA
--------------------------------

-- The decision tree algorithm is very capable of handling data which
-- has not been specially prepared.  For this example, no data preparation
-- will be performed.
--

-------------------
-- SPECIFY SETTINGS
-------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE dt_sh_sample_cost';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
 
--------------------------
-- CREATE AND POPULATE A COST MATRIX TABLE
--------------------------

-- A cost matrix is used to influence the weighting of misclassification
-- during model creation (and scoring).
-- See Oracle Data Mining Concepts Guide for more details.
--

CREATE TABLE dt_sh_sample_cost (
  actual_target_value           NUMBER,
  predicted_target_value        NUMBER,
  cost                          NUMBER);
INSERT INTO dt_sh_sample_cost VALUES (0,0,0);
INSERT INTO dt_sh_sample_cost VALUES (0,1,1);
INSERT INTO dt_sh_sample_cost VALUES (1,0,8);
INSERT INTO dt_sh_sample_cost VALUES (1,1,0);


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('DT_SH_Clas_sample');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst(dbms_data_mining.algo_name) := dbms_data_mining.algo_decision_tree;
  v_setlst(dbms_data_mining.clas_cost_table_name) := 'dt_sh_sample_cost';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'DT_SH_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_query          => 'SELECT * FROM mining_data_build_parallel_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    set_list            => v_setlst
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
  EXECUTE IMMEDIATE 'DROP TABLE dt_sh_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('DT_SH_Clas_sample');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE dt_sh_sample_settings (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO dt_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_decision_tree);
    INSERT INTO dt_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.clas_cost_table_name, 'dt_sh_sample_cost');
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'DT_SH_Clas_sample',
      mining_function     => dbms_data_mining.classification,
      data_table_name     => 'mining_data_build_parallel_v',
      case_id_column_name => 'cust_id',
      target_column_name  => 'affinity_card',
      settings_table_name => 'dt_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
-------------------------

column setting_name format a30
column setting_value format a30

SELECT setting_name, setting_value
FROM user_mining_model_settings
WHERE model_name = 'DT_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--------------------------

column attribute_name format a40
column attribute_type format a20

SELECT attribute_name, attribute_type
FROM user_mining_model_attributes
WHERE model_name = 'DT_SH_CLAS_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
-- NOTE: The "&quot" characters in this XML output are owing to
--       SQL*Plus behavior. Cut and paste this XML into a file,
--       and open the file in a browser to see correctly formatted XML.
--

column dt_details format a320

SELECT 
 dbms_data_mining.get_model_details_xml('DT_SH_Clas_sample') 
 AS DT_DETAILS
FROM dual;

--------------------------
-- DISPLAY MODEL VIEWS
--------------------------


-- Get a list of model views

col view_name format a30
col view_type format a50

SELECT view_name, view_type FROM user_mining_model_views
WHERE model_name='DT_SH_CLAS_SAMPLE'
ORDER BY view_name;

column ATTRIBUTE_NAME format a12
column VAL format a12
column split_type format a12
column OPERATOR format a12
  
-- Information about the splits in the hierarchy

SELECT * FROM (  
SELECT parent, split_type, node, attribute_name, operator, split.val 
FROM DM$VPDT_SH_CLAS_sample a,
XMLTABLE( '/Element' passing a.value
    columns 
    val varchar2(20) path '.') split
ORDER BY 1,2,3,4,5,6)
WHERE ROWNUM < 20;

-- Information about node statistics

SELECT node, node_support, predicted_target_value, target_value,
  target_support 
FROM DM$VIDT_SH_CLAS_SAMPLE ORDER BY 1,2,3,4,5;

-- Information about the nodes in the decision tree

SELECT * FROM (
SELECT node, node_support, predicted_target_value, parent,
  attribute_name, operator, split.val
FROM DM$VODT_SH_CLAS_SAMPLE a,
XMLTABLE( '/Element' passing a.value
    columns 
    val varchar2(20) path '.') split  
ORDER BY 1,2,3,4,5,6,7)
WHERE ROWNUM < 20;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

--------------------
-- PREPARE TEST DATA
--------------------

-- If the data for model creation has been prepared, then the data used
-- for testing the model must be prepared to the same scale in order to
-- obtain meaningful results.
-- In this case, no data preparation is necessary since model creation
-- was performed on the raw (unprepared) input.
--

------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
------------------------------------

-- Other demo programs demonstrate how to use the PL/SQL API to
-- compute a number of metrics, including lift and ROC.  This demo
-- only computes a confusion matrix and accuracy, but it does so 
-- using the SQL data mining functions.
--

-- In this example, we experiment with using the cost matrix
-- that was provided to the create routine.  In this example, the 
-- cost matrix reduces the problematic misclassifications, but also 
-- negatively impacts the overall model accuracy.

-- DISPLAY CONFUSION MATRIX WITHOUT APPLYING COST MATRIX
--

SELECT affinity_card AS actual_target_value, 
       PREDICTION(DT_SH_Clas_sample USING *) AS predicted_target_value,
       COUNT(*) AS value
FROM mining_data_test_parallel_v
GROUP BY affinity_card, PREDICTION(DT_SH_Clas_sample USING *)
ORDER BY 1,2;

-- DISPLAY CONFUSION MATRIX APPLYING THE COST MATRIX
--

SELECT affinity_card AS actual_target_value, 
       PREDICTION(DT_SH_Clas_sample COST MODEL USING *) 
         AS predicted_target_value,
       COUNT(*) AS value
FROM mining_data_test_parallel_v
GROUP BY affinity_card, PREDICTION(DT_SH_Clas_sample COST MODEL USING *)
ORDER BY 1,2;

-- DISPLAY ACCURACY WITHOUT APPLYING COST MATRIX
--

SELECT ROUND(SUM(correct)/COUNT(*),4) AS accuracy
FROM (SELECT DECODE(affinity_card,
               PREDICTION(DT_SH_Clas_sample USING *), 1, 0) AS correct
FROM mining_data_test_parallel_v);

-- DISPLAY ACCURACY APPLYING THE COST MATRIX
--

SELECT ROUND(SUM(correct)/COUNT(*),4) AS accuracy
FROM (SELECT DECODE(affinity_card,
                 PREDICTION(DT_SH_Clas_sample COST MODEL USING *),
                 1, 0) AS correct
FROM mining_data_test_parallel_v);

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

------------------
-- BUSINESS CASE 1
------------------

-- Find the 10 customers who live in Italy that are least expensive
-- to be convinced to use an affinity card.
--

SELECT cust_id FROM
(SELECT cust_id, 
        rank() OVER (ORDER BY PREDICTION_COST(DT_SH_Clas_sample, 
                     1 COST MODEL USING *) ASC, cust_id) rnk
FROM mining_data_apply_parallel_v
WHERE country_name = 'Italy')
WHERE rnk <= 10
ORDER BY rnk;

------------------
-- BUSINESS CASE 2
------------------

-- Find the average age of customers who are likely to use an
-- affinity card.
-- Include the build-time cost matrix in the PREDICTION.
-- Only take into account CUST_MARITAL_STATUS, EDUCATION, and
-- HOUSEHOLD_SIZE as predictors.
-- Break out the results by gender.
--

column cust_gender format a12

SELECT cust_gender, COUNT(*) AS cnt, ROUND(AVG(age)) AS avg_age
FROM mining_data_apply_parallel_v
WHERE PREDICTION(dt_sh_clas_sample COST MODEL
                 USING cust_marital_status, education, household_size) = 1
GROUP BY cust_gender
ORDER BY cust_gender;

------------------
-- BUSINESS CASE 3
------------------

-- List ten customers (ordered by their id) along with likelihood and cost
-- to use or reject the affinity card (Note: while this example has a
-- binary target, such a query is useful in multi-class classification -
-- Low, Med, High for example).
--

column PREDICTION format 9;
column probability format 9.999999999
column cost format 9.999999999

SELECT T.cust_id, S.PREDICTION, S.probability, S.cost
FROM (SELECT cust_id,
               PREDICTION_SET(dt_sh_clas_sample COST MODEL USING *) pset
FROM mining_data_apply_parallel_v
WHERE cust_id < 100011) T,
       TABLE(T.pset) S
ORDER BY cust_id, S.PREDICTION;

------------------
-- BUSINESS CASE 4
------------------

-- Find the segmentation (resulting tree node and rule) for customers who
-- work in Tech support and are under 25.
--

set long 20000
set line 300
set pagesize 100
column education format a30;

SELECT cust_id, education,
       PREDICTION_DETAILS(dt_sh_clas_sample USING *) prediction_details 
FROM mining_data_apply_parallel_v
WHERE occupation = 'TechSup' AND age < 25
ORDER BY cust_id;

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('DT_SH_CLAS_SAMPLE');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE DT_SH_SAMPLE_COST';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE DT_SH_SAMPLE_SETTINGS';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
