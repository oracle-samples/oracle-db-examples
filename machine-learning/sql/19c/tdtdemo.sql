Rem
Rem $Header: tk_datamining/tmdm/sql/tdtdemo.sql /main/7 2011/09/19 17:07:40 amozes Exp $
Rem
Rem tdtdemo.sql
Rem
Rem Copyright (c) 2004, 2011, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      tdtdemo.sql - Sample program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for classification function (Decision Trees). 
Rem
Rem    NOTES
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    amozes      05/26/11 - remove xdb pretty print
Rem    jiawang     11/13/06 - Set pretty print
Rem    mmcracke    10/24/05 - Change case_id to ID. 
Rem    mjaganna    11/12/04 - Remove priors references
Rem    amozes      08/04/04 - singular dtree 
Rem    amozes      07/13/04 - amozes_bug-3756145
Rem    amozes      07/12/04 - Created
Rem

SET serveroutput ON
SET trimspool ON
SET pages 10000
SET long 2000000000
SET pagesize 0

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- disable binning
alter session set "_dtree_binning_enabled"=false;
--------------------------------
-- PREPARE BUILD (TRAINING) DATA
--
-- The decision tree algorithm is very capable at handling data which
-- has not been specially prepared.  In this case, no data preparation
-- will be performed.
--


--------------------------------------
-- CLEANUP OLD SETTINGS TABLE (IF ANY)
--
BEGIN
  -- Drop the Settings Table
  EXECUTE IMMEDIATE 'DROP TABLE dt_sample_settings';
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/

-- DROP OLD COST MATRIX TABLE (IF ANY)
--
BEGIN
  -- Drop any existing Cost Table
  EXECUTE IMMEDIATE 'DROP TABLE dt_sample_cost';  
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/
 
--------------------------
-- CREATE A SETTINGS TABLE
--
-- The default classification algorithm is Naive Bayes. In order to override
-- this, create and populate a settings table to be used as input for
-- CREATE_MODEL.
-- 
CREATE TABLE dt_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(30));
 
-- CREATE AND POPULATE A COST MATRIX TABLE
--
-- A cost matrix is used to influence the weighting of misclassification
-- during model creation (and scoring).
-- See Concepts Guide for more details.
--
CREATE TABLE dt_sample_cost (
  actual_target_value           NUMBER,
  predicted_target_value        NUMBER,
  cost                          NUMBER);
INSERT INTO dt_sample_cost VALUES (0,0,0);
INSERT INTO dt_sample_cost VALUES (0,1,1);
INSERT INTO dt_sample_cost VALUES (1,0,5);
INSERT INTO dt_sample_cost VALUES (1,1,0);
COMMIT;

BEGIN       
  -- Populate settings table
  INSERT INTO dt_sample_settings VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_decision_tree);
  INSERT INTO dt_sample_settings VALUES
    (dbms_data_mining.clas_cost_table_name, 'dt_sample_cost');
  COMMIT;

  -- Examples of other possible overrides are:
  --(dbms_data_mining.tree_impurity_metric, 'TREE_IMPURITY_ENTROPY')
  --(dbms_data_mining.tree_term_max_depth, 5)
  --(dbms_data_mining.tree_term_minrec_split, 5)
  --(dbms_data_mining.tree_term_minpct_split, 2)
  --(dbms_data_mining.tree_term_minrec_node, 5)
  --(dbms_data_mining.tree_term_minpct_noe, 0.05)
  dbms_output.put_line('Populated settings');
END;
/

--------------------------------------------
-- CLEANUP OLD MODEL WITH SAME NAME (IF ANY)
--
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('DT_Clas_sample');
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/

---------------------
-- CREATE A NEW MODEL
--
BEGIN
  DBMS_OUTPUT.PUT_LINE('Begin CREATE_MODEL - DT - Classification');
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'DT_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build',
    case_id_column_name => 'id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'dt_sample_settings');
  DBMS_OUTPUT.PUT_LINE('End   CREATE_MODEL - DT - Classification');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
BEGIN DBMS_OUTPUT.PUT_LINE('Display MODEL SETTINGS'); END;
/
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_SETTINGS('DT_Clas_sample'))
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
BEGIN DBMS_OUTPUT.PUT_LINE('Display MODEL SIGNATURE'); END;
/
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_SIGNATURE('DT_Clas_sample'))
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--

BEGIN DBMS_OUTPUT.PUT_LINE('Display MODEL DETAILS'); END;
/
SELECT 
 dbms_data_mining.get_model_details_xml('DT_Clas_sample')
 AS DT_DETAILS
FROM dual;


-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------


--------------------
-- PREPARE TEST DATA
--
-- If the data for model creation has been prepared, then the data used
-- for testing the model must be prepared to the same scale in order to
-- obtain meaningful results.
-- In this case, no data preparation is necessary since model creation
-- was performed on the raw (unprepared) input.
--


------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--
-- Other demo programs demonstrate how to use the PL/SQL API to
-- compute a number of metrics, including lift and ROC.  This demo
-- only computes a confusion matrix and accuracy, but it does so 
-- using the SQL prediction function.
--
-- In this example, we experiment with using the cost matrix
-- that was provided to the create routine.  In this example, the 
-- cost matrix reduces the problematic misclassifications, but also 
-- negatively impacts the overall model accuracy.

-- DISPLAY CONFUSION MATRIX WITHOUT APPLYING COST MATRIX
--
BEGIN DBMS_OUTPUT.PUT_LINE('Display CONFUSION MATRIX NO COST'); END;
/
SELECT affinity_card as actual_target_value, 
       prediction(DT_Clas_sample using *) 
       as predicted_target_value,
       count(*) as value
FROM mining_data_test
GROUP BY affinity_card,
         prediction(DT_Clas_sample using *)
ORDER BY 1,2;

-- DISPLAY CONFUSION MATRIX WITH APPLYING COST MATRIX
--
BEGIN DBMS_OUTPUT.PUT_LINE('Display CONFUSION MATRIX WITH COST'); END;
/
SELECT affinity_card as actual_target_value, 
       prediction(DT_Clas_sample cost model using *) 
       as predicted_target_value,
       count(*) as value
FROM mining_data_test
GROUP BY affinity_card,
         prediction(DT_Clas_sample cost model using *)
ORDER BY 1,2;

-- DISPLAY ACCURACY WITHOUT APPLYING COST MATRIX
--
BEGIN DBMS_OUTPUT.PUT_LINE('Display ACCURACY NO COST'); END;
/
SELECT round(sum(correct)/count(*),4) as accuracy FROM (
 SELECT decode(affinity_card,
               prediction(DT_Clas_sample using *),
               1, 0) as correct
 FROM mining_data_test);

-- DISPLAY ACCURACY WITH APPLYING COST MATRIX
--
BEGIN DBMS_OUTPUT.PUT_LINE('Display ACCURACY WITH COST'); END;
/
SELECT round(sum(correct)/count(*),4) as accuracy FROM (
 SELECT decode(affinity_card,
               prediction(DT_Clas_sample cost model using *),
               1, 0) as correct
 FROM mining_data_test);


-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------


BEGIN
  -- Drop the result table
  EXECUTE IMMEDIATE 'DROP TABLE mining_data_result';
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('Applying the model'); END;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Begin APPLY - DT - Classification');
  dbms_data_mining.apply(model_name => 'DT_Clas_sample',
                data_table_name => 'mining_data_apply',
                case_id_column_name => 'id',
                result_table_name => 'mining_data_result');
  DBMS_OUTPUT.PUT_LINE('End   APPLY - DT - Classification');
END;
/
column id format 99999999
column prediction format 9999
column probability format 9.9999
select * from (select id, prediction, probability from mining_data_result order by 1, 2) where rownum < 21;
