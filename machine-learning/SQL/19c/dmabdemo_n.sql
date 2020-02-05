Rem
Rem $Header: tk_datamining/tmdm/sql/dmabdemo_n.sql /main/3 2010/11/04 13:28:39 xbarr Exp $
Rem
Rem dmabdemo_n.sql
Rem
Rem Copyright (c) 2005, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      dmabdemo_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for classification function using the ABN Algorithm
Rem      against the SH (Sales History) schema in the RDBMS.
Rem
Rem      This sample demonstrates the backward compatibility of
Rem      procedures for computing test metrics, apply and ranked apply.
Rem      Other samples demonstrate the use of the new SQL functions
Rem      for data mining in Oracle10gR2.
Rem
Rem    NOTES
Rem      Refer to dmabdemo.slq for detail
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       10/25/10 - binary_double formatting
Rem    jcjeon      09/10/08 - sync testcase with sb
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/17/05 - Created
Rem
  
SET serveroutput ON
SET trimspool ON
SET pages 10000
SET linesize 100
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic data about a set of customers, predict the
-- customer response to an affinity card program using a classifier
-- based on ABN algorithm.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).

-----------
-- ANALYSIS
-----------
-- For classification using ABN, perform the following on mining data.
--
-- 1. Missing Value Treatment for Predictors
--
--    See dmsvcdem.sql for a definition of missing values, and the
--    steps to be taken for missing value imputation.
--
--    ABN/NB treats NULL values for attributes as missing at random.
--
-- 2. Outlier Treatment for Predictors for Build data
--
--    See dmsvcdem.sql for a discussion on outlier treatment.
--
--    ABN/NB (and Bayesian algorithms in general) require that high cardinality
--    data be binned. Studies have shown that equi-width binning into 10 bins
--    of data with no outliers provides good model performance. So if equiwidth
--    binning is considered, then outliers in the data have to be handled.
--    Not doing this would affect the bin boundaries such that data values
--    would tend to concentrate on too few bins. However ....
--
-- 3. Binning high cardinality data
--    You can skip step 2 if the data is binned using quantile binning
--    (10 bins, for starters). ODM recommends quantile binning for NB
--    and ABN.
--
-- eliminate old tables
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE mining_data_build_hist';
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/

-- Gather histogram and cardinality for attributes as preparation for binning
--
-- create table for column histogram
set echo off
CREATE GLOBAL TEMPORARY TABLE mining_data_build_hist (
  cname VARCHAR2(~~30), cnval NUMBER, csval VARCHAR2(~~30), vcnt NUMBER);

DECLARE
  cname  VARCHAR2(~~30);
  ctype  VARCHAR2(~~30);
  vstmt  VARCHAR2(4000);
  ccnt   NUMBER;
  CURSOR c1 IS
  SELECT column_name,data_type
    FROM all_tab_columns
   WHERE table_name='MINING_DATA_BUILD_V'
   ORDER BY column_name;
BEGIN
  OPEN c1;
  LOOP
    FETCH c1 INTO cname,ctype;
    EXIT WHEN c1%NOTFOUND;

    -- find cardinality
    vstmt := 'SELECT COUNT(DISTINCT ' || cname || ') FROM mining_data_build_v';
    EXECUTE IMMEDIATE vstmt INTO ccnt;
    DBMS_OUTPUT.PUT_LINE('Column: ' || cname || ', Card: ' || ccnt);

    -- find column histogram (skip case id) and store it in a temp table
    IF (cname != 'CUST_ID') THEN
      IF (ctype = 'NUMBER') THEN      -- num column histogram
        vstmt :=
        'INSERT INTO mining_data_build_hist (cname, cnval, vcnt) ' ||
        'SELECT ' || '''' || cname || '''' || ',' || cname || ',count(*) ' ||
          'FROM mining_data_build_v GROUP BY ' || cname;
      ELSIF (ctype = 'VARCHAR2') THEN -- str column histogram
        vstmt :=
        'INSERT INTO mining_data_build_hist (cname, csval, vcnt) ' ||
        'SELECT ' || '''' || cname || '''' || ',' || cname || ',count(*) ' ||
          'FROM mining_data_build_v GROUP BY ' || cname;
      END IF;
      EXECUTE IMMEDIATE vstmt;
    END IF;
  END LOOP;
END;
/
set echo on

-- Inspect COLUMN HISTOGRAMS
--
column cname format a25;
column cval  format a45;
SELECT cname, NVL(TO_CHAR(cnval), csval) cval, vcnt
  FROM mining_data_build_hist
ORDER BY 1,2,3;

-- . The target attribute is AFFINITY_CARD. CUST_ID is the case identifier.
--   The rest of the attributes are predictors.
-- . OCCUPATION has 15 distinct values, we decide to quantile bin it
--   into 7+1 bins.
-- . AGE has 66 distinct values in the range 17-80; we decide to quantile
--   bin it into 5+1 bins.
-- . All other attributes are categorical with binary values, so they
--   are not binned.

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup build data preparation objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_num';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_cat';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW abn_sh_sample_build_prepared';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW abn_sh_sample_build_cat';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('ABN_SH_Clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

--------------------------------
-- PREPARE BUILD (TRAINING) DATA
--
-- 1. Missing Value treatment for all Predictors
--    Skipped - see dmnbdemo.sql
--
-- 2. Outlier Treatment
--    Skipped - due to choice of quantile binning
--
-- 3. Binning
--
BEGIN
  -- Bin categorical attributes: OCCUPATION
  DBMS_DATA_MINING_TRANSFORM.CREATE_BIN_CAT (
    bin_table_name => 'abn_sh_sample_cat');        

  DBMS_DATA_MINING_TRANSFORM.INSERT_BIN_CAT_FREQ (
    bin_table_name  => 'abn_sh_sample_cat',
    data_table_name => 'mining_data_build_v',
    bin_num         => 7,
    exclude_list    => DBMS_DATA_MINING_TRANSFORM.COLUMN_LIST (
                       'cust_gender',
                       'cust_marital_status',
                       'cust_income_level',
                       'education',
                       'household_size')
  );

  -- Bin numerical attributes: AGE
  DBMS_DATA_MINING_TRANSFORM.CREATE_BIN_NUM (
    bin_table_name => 'abn_sh_sample_num');
                         
  DBMS_DATA_MINING_TRANSFORM.INSERT_BIN_NUM_QTILE (
    bin_table_name  => 'abn_sh_sample_num',
    data_table_name => 'mining_data_build_v',
    bin_num         => 5,
    exclude_list    => DBMS_DATA_MINING_TRANSFORM.COLUMN_LIST (
                       'affinity_card',
                       'bookkeeping_application',
                       'bulk_pack_diskettes',
                       'cust_id',
                       'flat_panel_monitor',
                       'home_theater_package',
                       'os_doc_set_kanji',
                       'printer_supplies',
                       'y_box_games')
  );

  -- Create the transformed view
  -- Execute the first transformation (categorical binning)
  DBMS_DATA_MINING_TRANSFORM.XFORM_BIN_CAT (
    bin_table_name  => 'abn_sh_sample_cat',
    data_table_name => 'mining_data_build_v',
    xform_view_name => 'abn_sh_sample_build_cat');    

  -- Provide the result (abn_sh_sample_build_cat)
  -- to the next transformation (numerical binning)
  DBMS_DATA_MINING_TRANSFORM.XFORM_BIN_NUM (
    bin_table_name  => 'abn_sh_sample_num',
    data_table_name => 'abn_sh_sample_build_cat',
    xform_view_name => 'abn_sh_sample_build_prepared');
END;
/

-- BUILD DATA PREPARATION OBJECTS:
-- ------------------------------
-- 1. Categorical Bin Table:        abn_sh_sample_cat
-- 2. Numerical Bin Table:          abn_sh_sample_num
-- 3. Input (view) to CREATE_MODEL: abn_sh_sample_build_prepared

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
--
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- CREATE AND POPULATE A PRIORS TABLE
--
-- See dmnbdemo.sql - Classification using NB algorithm - for an example.

-- NB is the default classifier. Override the default to ABN.
-- The default ABN model type is multi_feature. Override this
-- to single feature ABN (to demonstrate model details, since
-- get_model_details_abn() provides details only of single
-- feature ABN models. See Concepts Guide for distinction between
-- these models).
--
-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE abn_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(30));
set echo on
 
BEGIN       
  -- Populate settings table
  INSERT INTO abn_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.algo_name,dbms_data_mining.algo_adaptive_bayes_network);
  INSERT INTO abn_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.abns_model_type,dbms_data_mining.abns_single_feature);

  -- Examples of other possible overrides are:
  -- (dbms_data_mining.abns_max_build_minutes,10);
  -- (dbms_data_mining.abns_max_nb_predictors,19);
  -- (dbms_data_mining.abns_max_predictors,34);
  -- (dbms_data_mining.abns_model_type, dbms_data_mining.abns_multi_feature);
  -- (dbms_data_mining.abns_model_type, dbms_data_mining.abns_naive_bayes);
END;
/

---------------------
-- CREATE A NEW MODEL
--
-- Build a new ABN model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'ABN_SH_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'abn_sh_sample_build_prepared',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'abn_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'ABN_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'ABN_SH_CLAS_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- If the build data is prepared (as in this example), then the model
-- contains values of prepared data. The query shown below
-- reverse-transforms the model contents to be as close to the original
-- values as possible, based on the build data preparation objects.
-- Reporting the exact original value is impossible since the input
-- build data has already undergone some transformations (binning/
-- normalization etc.)
--
-- The SQL query presented below does the following.
-- 1. Use the bin boundary tables to create labels
-- 2. Replace attribute values with labels
-- 3. For numeric bins, the labels are "[/(lower_boundary,upper_boundary]/)"
-- 4. For categorical bins, label matches the value it represents
--    Note that this method of categorical label representation
--    will only work for cases where one value corresponds to one bin.
-- Target was not binned, hence we don't unbin the target.
--
-- You can replace the model name in the query with your own,
-- and also adapt the query to accomodate other transforms.
--
SET heading OFF
WITH
mod_dtls AS (
SELECT *
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_ABN('abn_sh_clas_sample'))
),
bin_labels AS (
SELECT col, bin, (DECODE(bin,'1','[','(') || lv || ',' || val || ']') label
  FROM (SELECT col,
               bin,
               LAST_VALUE(val) OVER (
                 PARTITION BY col ORDER BY val
                 ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) lv,
               val
          FROM abn_sh_sample_num)
UNION ALL
SELECT col, bin, val label
  FROM abn_sh_sample_cat
),
mod_ante AS (
SELECT R.rule_id, A.attribute_name Aa, A.conditional_operator Ac,
       NVL(L.label, NVL(A.attribute_str_value,A.attribute_num_value))
         antecedent,
       A.attribute_support antecedent_support,
       A.attribute_confidence antecedent_confidence
  FROM mod_dtls R,
       TABLE(R.antecedent) A,
       bin_labels L
 WHERE A.attribute_name = L.col (+) AND
       (NVL(A.attribute_str_value,A.attribute_num_value) = L.bin(+))
),
mod_cons AS (
SELECT R.rule_id, C.attribute_name Ca, C.conditional_operator Cc,
       NVL(L.label, NVL(C.attribute_str_value,C.attribute_num_value))
         consequent,
       C.attribute_support consequent_support,
       C.attribute_confidence consequent_confidence
  FROM mod_dtls R,
       TABLE(R.consequent) C,
       bin_labels L
 WHERE C.attribute_name = L.col (+) AND
       (NVL(C.attribute_str_value,C.attribute_num_value) = L.bin(+))
),
model_details AS (
SELECT R.rule_support, R.rule_id,
       ante.Aa, ante.Ac, ante.antecedent, ante.antecedent_support,
       ROUND(ante.antecedent_confidence,4) antecedent_confidence,
       cons.Ca, cons.Cc, cons.consequent, cons.consequent_support,
       ROUND(cons.consequent_confidence, 4) consequent_confidence
  FROM mod_dtls R,
       mod_ante ante,
       mod_cons cons
 WHERE R.rule_id = ante.rule_id AND ante.rule_id = cons.rule_id
ORDER BY R.rule_support DESC,
         consequent_confidence DESC, cons.Ca, cons.consequent,
         antecedent_confidence DESC, ante.Aa, ante.antecedent
)
SELECT 'Rule Support: ' || ROUND(rule_support, 4),
--     ' Rule Id: '     || rule_id ,
       ' Antecedent attribute: ' || Aa || ' ' || Ac || ' ' || antecedent,
       ' Consequent attribute: ' || Ca || ' ' || Cc || ' ' || consequent,
       ' Antecedent support: ' || antecedent_support,
       ' Antecedent confidence: ' || antecedent_confidence,
       ' Consequent support: ' || consequent_support,
       ' Consequent confidence: ' || consequent_confidence
  FROM model_details
 WHERE ROWNUM < 21;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

-- Cleanup test data preparation objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP VIEW abn_sh_sample_test_targets';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW abn_sh_sample_test_prepared';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW abn_sh_sample_test_cat';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

--------------------
-- PREPARE TEST DATA
--
-- If the data for model creation has been prepared, then the data used
-- for testing the model must be prepared to the same scale in order to
-- obtain meaningful results.
--
-- 1. Missing value treatment - see dmsvcdem.sql for example of what
--    needs to be done with Test and Apply data input.
--
-- 2. Outlier treatment and
-- 3. Binning
-- Quantile binning handles both the outlier treatment and binning in this case.
-- Transform the test data mining_test_v, using the transformation tables
-- generated during the Build data preparation, to generate a view representing
-- prepared test data.
--
-- If this model is tested in a different schema or instance, the 
-- data preparation objects generated in the CREATE step must also
-- be made available in the target schema/instance. So you must export
-- those objects (i.e. the num and cat bin tables and views) along with 
-- the model to the target user schema.
--
BEGIN
  -- Execute the first transform effected on training data
  DBMS_DATA_MINING_TRANSFORM.XFORM_BIN_CAT (
    bin_table_name  => 'abn_sh_sample_cat',
    data_table_name => 'mining_data_test_v',
    xform_view_name => 'abn_sh_sample_test_cat');

  -- Provide the result to the next transform effected on training data
  DBMS_DATA_MINING_TRANSFORM.XFORM_BIN_NUM (
    bin_table_name  => 'abn_sh_sample_num',
    data_table_name => 'abn_sh_sample_test_cat',
    xform_view_name => 'abn_sh_sample_test_prepared');
END;
/

-- Cleanup test result objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_test_apply';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_confusion_matrix';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_lift';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_roc';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

---------------------------------
-- SPECIFY COST MATRIX (OPTIONAL)
--
-- (See dmsvcdem.sql - SVM Classification - for example)
--

------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--
-- The COMPUTE interfaces that provide the test results require two
-- data inputs:
-- 1. A table or view of targets - i.e. one that provides only the
--    case identifier and target columns of your test data.
-- 2. The table with the results of an APPLY operation on test data.
--

-- CREATE TEST TARGETS VIEW
--
CREATE VIEW abn_sh_sample_test_targets AS
SELECT cust_id, affinity_card
  FROM abn_sh_sample_test_prepared;

-- APPLY MODEL ON TEST DATA
--
BEGIN
  DBMS_DATA_MINING.APPLY(
    model_name          => 'ABN_SH_Clas_sample',
    data_table_name     => 'abn_sh_sample_test_prepared',
    case_id_column_name => 'cust_id',
    result_table_name   => 'abn_sh_sample_test_apply');
END;
/

-- COMPUTE TEST METRICS
--
DECLARE
  v_accuracy         NUMBER;
  v_area_under_curve NUMBER;
BEGIN
   DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
     accuracy                    => v_accuracy,
     apply_result_table_name     => 'abn_sh_sample_test_apply',
     target_table_name           => 'abn_sh_sample_test_targets',
     case_id_column_name         => 'cust_id',
     target_column_name          => 'affinity_card',
     confusion_matrix_table_name => 'abn_sh_sample_confusion_matrix',
     score_column_name           => 'PREDICTION',
     score_criterion_column_name => 'PROBABILITY');
   DBMS_OUTPUT.PUT_LINE('**** MODEL ACCURACY ****: ' || ROUND(v_accuracy, 4));
 
   DBMS_DATA_MINING.COMPUTE_LIFT (
     apply_result_table_name => 'abn_sh_sample_test_apply',
     target_table_name       => 'abn_sh_sample_test_targets',
     case_id_column_name     => 'cust_id',
     target_column_name      => 'affinity_card',
     lift_table_name         => 'abn_sh_sample_lift',
     positive_target_value   => '1',
     num_quantiles           => '10');

   DBMS_DATA_MINING.COMPUTE_ROC (
     roc_area_under_curve        => v_area_under_curve,
     apply_result_table_name     => 'abn_sh_sample_test_apply',
     target_table_name           => 'abn_sh_sample_test_targets',
     case_id_column_name         => 'cust_id',
     target_column_name          => 'affinity_card',
     roc_table_name              => 'abn_sh_sample_roc',
     positive_target_value       => '1',
     score_column_name           => 'PREDICTION',
     score_criterion_column_name => 'PROBABILITY');
   DBMS_OUTPUT.PUT_LINE('**** AREA UNDER ROC CURVE ****: ' || v_area_under_curve );
END;
/

-- TEST RESULT OBJECTS:
-- -------------------
-- 1. Confusion matrix Table: abn_sh_sample_confusion_matrix
-- 2. Lift Table:             abn_sh_sample_lift
-- 3. ROC Table:              abn_sh_sample_roc
--

-- 
-- DISPLAY CONFUSION MATRIX
--
-- NOTE: Cells with count 0 are not represented in the table
--
SET heading ON
column predicted format a20;
SELECT actual_target_value actual,
       to_char(predicted_target_value) predicted,
       value as count
  FROM abn_sh_sample_confusion_matrix
ORDER BY actual_target_value,predicted_target_value;

-- DISPLAY LIFT RESULTS
--
-- Uncomment the lines below to generate .csv for Lift charting using Excel
-- SET lines 32767
-- SET pages 0
-- SET colsep ","
-- SET feedback off
-- SET trimspool on
-- SPOOL dmabdemo.csv
SELECT quantile_number               qtl,
       lift_cumulative               lcume,
       percentage_records_cumulative prcume,
       targets_cumulative            tcume,
       target_density_cumulative     tdcume
-- Other info in Lift results
-- quantile_total_count,
-- target_density_cumulative,
-- non_targets_cumulative,
-- lift_quantile,
-- target_density
  FROM abn_sh_sample_lift
ORDER BY quantile_number;
-- SPOOL OFF

-- DISPLAY ROC - TOP 10 PROBABILITIES
--
column prob format 9.999999999
SELECT probability     prob,
       true_positives  tp,
       false_negatives fn,
       false_positives fp,
       true_negatives  tn,
       true_positive_fraction tpf,
       false_positive_fraction fpf
  FROM (SELECT * FROM abn_sh_sample_roc ORDER BY probability)
 WHERE ROWNUM < 11;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

-- Cleanup scoring data preparation objects for repeat runs
--
BEGIN EXECUTE IMMEDIATE 'DROP VIEW abn_sh_sample_apply_prepared';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW abn_sh_sample_apply_cat';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-----------------------
-- PREPARE SCORING DATA
--
-- If the data for model creation has been prepared, then the data to be
-- scored using the model must be prepared to the same scale in order to 
-- obtain meaningful results.
--
-- 1. Missing value treatment - see dmsvcdem.sql for example of what
--    needs to be done with Test and Apply data input.
--
-- 2. Outlier treatment and
-- 3. Binning
-- Quantile binning handles both the outlier treatment and binning in this case.
-- Transform the test data mining_test_v, using the transformation tables
-- generated during the Build data preparation, to generate a view representing
-- prepared test data.
--
-- If this model is applied in a different schema or instance, the 
-- data preparation objects generated in the CREATE step must also
-- be made available in the target schema/instance. So you must export
-- those objects (i.e. the num and cat bin tables and views) along with 
-- the model to the target user schema.
--
BEGIN
  -- Execute the first transform effected on training data
  DBMS_DATA_MINING_TRANSFORM.XFORM_BIN_CAT (
    bin_table_name  => 'abn_sh_sample_cat',
    data_table_name => 'mining_data_apply_v',
    xform_view_name => 'abn_sh_sample_apply_cat');   

  -- Provide the result to the next transform effected on training data
  DBMS_DATA_MINING_TRANSFORM.XFORM_BIN_NUM (
    bin_table_name  => 'abn_sh_sample_num',
    data_table_name => 'abn_sh_sample_apply_cat',
    xform_view_name => 'abn_sh_sample_apply_prepared');
END;
/

-- Cleanup scoring result objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE abn_sh_sample_apply_result';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

------------------
-- APPLY THE MODEL
--
BEGIN
  DBMS_DATA_MINING.APPLY(
    model_name          => 'ABN_SH_Clas_sample',
    data_table_name     => 'abn_sh_sample_apply_prepared',
    case_id_column_name => 'cust_id',
    result_table_name   => 'abn_sh_sample_apply_result');
END;
/

-- APPLY RESULT OBJECTS: abn_sh_sample_apply_result

------------------------
-- DISPLAY APPLY RESULTS
--
-- 1. The results table contains a prediction set - i.e. ALL the predictions
--    for a given case id, with their corresponding probability values.
-- 2. In this example, note that APPLY results do not need to be reverse
--    transformed, as done in the case of model details. This is because
--    class values of a classification target were not (required to be)
--    binned or normalized.
-- 3. Only the first 10 rows of the table are displayed here.
--
column prediction format a20
column probability format 9.999999
SELECT cust_id, TO_CHAR(prediction) AS prediction, probability
  FROM (SELECT cust_id, prediction, ROUND(probability,4) probability
          FROM abn_sh_sample_apply_result
        ORDER BY cust_id, prediction, probability)
 WHERE ROWNUM < 11
ORDER BY cust_id;
   
-----------------------------------------------------------
-- GENERATE RANKED APPLY RESULTS (OPTIONALLY BASED ON COST)
--
-- See dmsvmcdem.sql - SVM Classification - for example
--
