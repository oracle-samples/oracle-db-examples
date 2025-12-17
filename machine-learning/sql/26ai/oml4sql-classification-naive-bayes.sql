-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   Classification - Naïve Bayes Algorithm - dmnbdemo.sql
--   
--   Copyright (c) 2025 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic data about a set of customers, predict the
-- customer response to an affinity card program using a classifier
-- based on the Naive Bayes algorithm.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_parallel_v (build data)
-- mining_data_test_parallel_v  (test data)
-- mining_data_apply_parallel_v (apply data)
-- (See dmsh.sql for view definitions).

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_priors';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Algorithm setting:
-- NB is the default classifier, thus there is no need to specify 
-- the algorithm in settings table when the mining_function parameter
-- of the CREATE_MODEL operation specifies classification.

-- CREATE AND POPULATE A PRIORS TABLE
-- The priors represent the overall distribution of the target in
-- the population. By default, the priors are computed from the sample
-- (in this case, the build data). If the sample is known to be a
-- distortion of the population target distribution (because, say,
-- stratified sampling has been employed, or due to some other reason),
-- then the user can override the default by providing a priors table
-- as a setting for model creation. See Oracle Data Mining Concepts Guide
-- for more details.
-- 
CREATE TABLE nb_sh_sample_priors (
  target_value      NUMBER,
  prior_probability NUMBER);
INSERT INTO nb_sh_sample_priors VALUES (0,0.65);
INSERT INTO nb_sh_sample_priors VALUES (1,0.35);

-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE nb_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
set echo on
BEGIN       
  INSERT INTO nb_sh_sample_settings (setting_name, setting_value) VALUES 
    (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
  INSERT INTO nb_sh_sample_settings VALUES
    (dbms_data_mining.clas_priors_table_name, 'nb_sh_sample_priors');
END;
/

---------------------
-- CREATE A NEW MODEL
--
-- Cleanup old model with the same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('NB_SH_Clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Build a new NB model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'NB_SH_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_parallel_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'nb_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'NB_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'NB_SH_CLAS_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- If the build data is prepared (as in this example), then the training
-- data has been encoded. For numeric data, this means that ranges of
-- values have been grouped into bins.  For categorical data, the
-- categorical values may have been grouped into subsets.
--

set line 200 

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='NB_SH_CLAS_SAMPLE'
  ORDER BY view_name;

-- Naive Bayes Target Priors
column partition_name format a14 
column target_name format a11 
column target_value format 9999999999.9999999999
column prior_probability format 9999999999.9999999999
column count format 9999999999
SELECT partition_name,
       target_name,
       target_value, 
       prior_probability,
       count
  FROM DM$VPNB_SH_Clas_sample
ORDER BY 1,2,3,4,5;

-- Naive Bayes Conditional Probabilities
column partition_name format a14 
column target_name format a11 
column target_value format 9999999999.9999999999
column attribute_name format a14 
column attribute_subname format a17 
column attribute_value format a15 
column conditional_probability format 9999999999.9999999999
column count format 9999999999
SELECT partition_name,
       target_name,
       target_value,
       attribute_name,
       attribute_subname,
       attribute_value,
       conditional_probability,
       count
  FROM DM$VVNB_SH_Clas_sample
ORDER BY 1,2,3,4,5,6,7,8;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------


-- Cleanup old test result objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_test_apply';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_confusion_matrix';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_cm_no_cost';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_lift';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_roc';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_alter_cost';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_alter_confusion_matrix';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

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
CREATE OR REPLACE VIEW nb_sh_sample_test_targets AS
SELECT cust_id, affinity_card
  FROM mining_data_apply_parallel_v;

-- APPLY MODEL ON TEST DATA
--
BEGIN
  DBMS_DATA_MINING.APPLY(
    model_name          => 'NB_SH_Clas_sample',
    data_table_name     => 'mining_data_apply_parallel_v',
    case_id_column_name => 'cust_id',
    result_table_name   => 'nb_sh_sample_test_apply');
END;
/

----------------------------------
-- COMPUTE TEST METRICS, WITH COST
--
----------------------
-- Specify cost matrix
--
-- Consider an example where it costs $10 to mail a promotion to a
-- prospective customer and if the prospect becomes a customer, the
-- typical sale including the promotion, is worth $100. Then the cost
-- of missing a customer (i.e. missing a $100 sale) is 10x that of
-- incorrectly indicating that a person is good prospect (spending
-- $10 for the promo). In this case, all prediction errors made by
-- the model are NOT equal. To act on what the model determines to
-- be the most likely (probable) outcome may be a poor choice.
--
-- Suppose that the probability of a BUY reponse is 10% for a given
-- prospect. Then the expected revenue from the prospect is:
--   .10 * $100 - .90 * $10 = $1.
-- The optimal action, given the cost matrix, is to simply mail the
-- promotion to the customer, because the action is profitable ($1).
--
-- In contrast, without the cost matrix, all that can be said is
-- that the most likely response is NO BUY, so don't send the
-- promotion.
--
-- This shows that cost matrices can be very important. 
--
-- The caveat in all this is that the model predicted probabilities
-- may NOT be accurate. For binary targets, a systematic approach to
-- this issue exists. It is ROC, illustrated below. 
--
-- With ROC computed on a test set, the user can see how various model 
-- predicted probability thresholds affect the action of mailing a promotion.
-- Suppose I promote when the probability to BUY exceeds 5, 10, 15%, etc. 
-- What return can I expect? Note that the answer to this question does
-- not rely on the predicted probabilities being accurate, only that
-- they are in approximately the correct rank order. 
--
-- Assuming that the predicted probabilities are accurate, provide the
-- cost matrix table name as input to the RANK_APPLY procedure to get
-- appropriate costed scoring results to determine the most appropriate
-- action.

-- Cleanup old cost matrix table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_cost';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- CREATE A COST MATRIX TABLE
--
CREATE TABLE nb_sh_cost (
  actual_target_value    NUMBER,
  predicted_target_value NUMBER,
  cost                   NUMBER);

-- POPULATE THE COST MATRIX
--
INSERT INTO nb_sh_cost VALUES (0,0,0);
INSERT INTO nb_sh_cost VALUES (0,1,.35);
INSERT INTO nb_sh_cost VALUES (1,0,.65);
INSERT INTO nb_sh_cost VALUES (1,1,0);

-- Compute Test Metrics
DECLARE
  v_accuracy         NUMBER;
  v_area_under_curve NUMBER;
BEGIN
   DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
     accuracy                    => v_accuracy,
     apply_result_table_name     => 'nb_sh_sample_test_apply',
     target_table_name           => 'nb_sh_sample_test_targets',
     case_id_column_name         => 'cust_id',
     target_column_name          => 'affinity_card',
     confusion_matrix_table_name => 'nb_sh_sample_confusion_matrix',
     score_column_name           => 'PREDICTION',   -- default
     score_criterion_column_name => 'PROBABILITY',  -- default
     cost_matrix_table_name      => 'nb_sh_cost');
   DBMS_OUTPUT.PUT_LINE('**** MODEL ACCURACY ****: ' || ROUND(v_accuracy,4));
 
   DBMS_DATA_MINING.COMPUTE_LIFT (
     apply_result_table_name => 'nb_sh_sample_test_apply',
     target_table_name       => 'nb_sh_sample_test_targets',
     case_id_column_name     => 'cust_id',
     target_column_name      => 'affinity_card',
     lift_table_name         => 'nb_sh_sample_lift',
     positive_target_value   => '1',
     num_quantiles           => '10',
     cost_matrix_table_name  => 'nb_sh_cost');

   DBMS_DATA_MINING.COMPUTE_ROC (
     roc_area_under_curve        => v_area_under_curve,
     apply_result_table_name     => 'nb_sh_sample_test_apply',
     target_table_name           => 'nb_sh_sample_test_targets',
     case_id_column_name         => 'cust_id',
     target_column_name          => 'affinity_card',
     roc_table_name              => 'nb_sh_sample_roc',
     positive_target_value       => '1',
     score_column_name           => 'PREDICTION',
     score_criterion_column_name => 'PROBABILITY');
   DBMS_OUTPUT.PUT_LINE('**** AREA UNDER ROC CURVE ****: ' ||
     ROUND(v_area_under_curve,4));
END;
/

-- TEST RESULT OBJECTS:
-- -------------------
-- 1. Confusion matrix Table: nb_sh_sample_confusion_matrix
-- 2. Lift Table:             nb_sh_sample_lift
-- 3. ROC Table:              nb_sh_sample_roc
--

-- DISPLAY CONFUSION MATRIX
--
-- NOTES ON COST (contd):
-- This section illustrates the effect of the cost matrix on the per-class
-- errors in the confusion matrix. First, compute the Confusion Matrix with
-- costs. Our cost matrix assumes that ratio of the cost of an error in 
-- class 1 to class 0 is 65:35 (where 1 => BUY and 0 => NO BUY).

column predicted format 9;
SELECT actual_target_value as actual, 
       predicted_target_value as predicted, 
       value as count
  FROM nb_sh_sample_confusion_matrix
ORDER BY actual_target_value, predicted_target_value;

-- Confusion matrix with Cost:
--    869  285
--     55  291

-- Compute the confusion matrix without costs for later analysis
DECLARE
  v_accuracy         NUMBER;
  v_area_under_curve NUMBER;
BEGIN
   DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
     accuracy                    => v_accuracy,
     apply_result_table_name     => 'nb_sh_sample_test_apply',
     target_table_name           => 'nb_sh_sample_test_targets',
     case_id_column_name         => 'cust_id',
     target_column_name          => 'affinity_card',
     confusion_matrix_table_name => 'nb_sh_sample_cm_no_cost',
     score_column_name           => 'PREDICTION',
     score_criterion_column_name => 'PROBABILITY');
   DBMS_OUTPUT.PUT_LINE('** ACCURACY W/ NO COST **: ' || ROUND(v_accuracy,4));
END;
/

-- Confusion matrix without Cost:
--
column predicted format 9;
SELECT actual_target_value as actual, 
       predicted_target_value as predicted, 
       value as count
  FROM nb_sh_sample_cm_no_cost
ORDER BY actual_target_value, predicted_target_value;

-- Confusion matrix without Cost:
--    901  253
--     60  286
--
-- Several points are illustrated here:
-- 1. The cost matrix causes an increase in class 1 accuracy
--    at the expense of class 0 accuracy
-- 2. The overall accuracy is down

-- DISPLAY ROC - TOP PROBABILITIE THRESHOLDS LEADING TO MINIMIZED COST
--
column prob format .9999
column tp format 9999
column fn format 9999
column fp format 9999
column tn format 9999
column tpf format 9.9999
column fpf format 9.9999
column nb_cost format 9999.99
SELECT *
  FROM (SELECT ROUND(probability,4) prob,
               true_positives  tp,
               false_negatives fn,
               false_positives fp,
               true_negatives  tn,
               ROUND(true_positive_fraction,4) tpf,
               ROUND(false_positive_fraction,4) fpf,
               .35 * false_positives + .65 * false_negatives nb_cost
         FROM nb_sh_sample_roc)
 WHERE nb_cost < 130
 ORDER BY nb_cost;

-- Here we see 13 different probability thresholds resulting in
-- confusion matrices with an overall cost below 130.
--
-- Now, let us create a cost matrix from the optimal threshold, i.e.,
-- one whose action is to most closely mimic the user cost matrix.
-- Let Poptimal = Probability corresponding to the minimum cost
--                computed from the ROC table above
--
-- Find the ratio of costs that causes breakeven expected cost at
-- at the optimal probability threshold:
--
--    Cost(misclassify 1) = (1 - Poptimal)/Poptimal
--    Cost(misclassify 0) = 1.0
--
-- The following query constructs the alternative cost matrix
-- based on the above rationale.
--
CREATE TABLE nb_alter_cost AS
WITH
cost_q AS (
SELECT probability,
       (.35 * false_positives + .65 * false_negatives) nb_cost
  FROM nb_sh_sample_roc
),
min_cost AS (
SELECT MIN(nb_cost) mincost
  FROM cost_q
),
prob_q AS (
SELECT min(probability) prob
  FROM cost_q, min_cost
 WHERE nb_cost = mincost
)
SELECT 1 actual_target_value,
       0 predicted_target_value, 
       (1.0 - prob)/prob cost
  FROM prob_q
UNION ALL 
SELECT 0 actual_target_value,
       1 predicted_target_value,
       1 cost
  FROM dual
UNION ALL 
SELECT 0 actual_target_value,
       0 predicted_target_value,
       0 cost
  FROM dual
UNION ALL
SELECT 1 actual_target_value,
       1 predicted_target_value,
       0 cost
  FROM dual;


column cost format 9.999999999
SELECT ACTUAL_TARGET_VALUE, PREDICTED_TARGET_VALUE, COST
  FROM nb_alter_cost;

-- Now, use this new cost matrix to compute the confusion matrix
--
DECLARE
  v_accuracy         NUMBER;
  v_area_under_curve NUMBER;
BEGIN
   DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
     accuracy                    => v_accuracy,
     apply_result_table_name     => 'nb_sh_sample_test_apply',
     target_table_name           => 'nb_sh_sample_test_targets',
     case_id_column_name         => 'cust_id',
     target_column_name          => 'affinity_card',
     confusion_matrix_table_name => 'nb_sh_alter_confusion_matrix',
     score_column_name           => 'PREDICTION',   -- default
     score_criterion_column_name => 'PROBABILITY',  -- default
     cost_matrix_table_name      => 'nb_alter_cost');
   DBMS_OUTPUT.PUT_LINE('**** MODEL ACCURACY ****: ' || ROUND(v_accuracy,4)); 
END;
/

SELECT actual_target_value as actual, 
       predicted_target_value as predicted, 
       value as count
  FROM nb_sh_alter_confusion_matrix
  ORDER BY actual_target_value, predicted_target_value;

-- DISPLAY LIFT RESULTS
--
SELECT quantile_number               qtl,
       lift_cumulative               lcume,
       percentage_records_cumulative prcume,
       targets_cumulative            tcume,
       target_density_cumulative     tdcume
-- Other info in Lift results
-- quantile_total_count,
-- non_targets_cumulative,
-- lift_quantile,
-- target_density
  FROM nb_sh_sample_lift
ORDER BY quantile_number;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

-- Cleanup old scoring result objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_apply_result';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_sh_sample_apply_ranked';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

------------------
-- APPLY THE MODEL
--
BEGIN
  DBMS_DATA_MINING.APPLY(
    model_name          => 'NB_SH_Clas_sample',
    data_table_name     => 'mining_data_apply_parallel_v',
    case_id_column_name => 'cust_id',
    result_table_name   => 'nb_sh_sample_apply_result');
END;
/

-- APPLY RESULT OBJECTS: nb_sh_sample_apply_result

------------------------
-- DISPLAY APPLY RESULTS
--
-- 1. The results table contains a prediction set - i.e. ALL the predictions
--    for a given case id, with their corresponding probability values.
-- 2. Only the first 10 rows of the table are displayed here.
--
column probability format 9.99999
column prediction format 9
SELECT cust_id, prediction, ROUND(probability,4) probability
  FROM nb_sh_sample_apply_result
 WHERE cust_id <= 100005
ORDER BY cust_id, prediction;
   
-----------------------------------------------------------
-- GENERATE RANKED APPLY RESULTS (OPTIONALLY BASED ON COST)
--
-- ALTER APPLY RESULTS TABLE (just for demo purposes)
--
-- The RANK_APPLY and COMPUTE() procedures do not necessarily have
-- to work on the result table generated from DBMS_DATA_MINING.APPLY
-- alone. They can work on any table with similar schema and content
-- that matches the APPLY result table. An example will be a table
-- generated from some other tool, scoring engine or a generated result.
--
-- To demonstrate this, we will make a simply change the column names in
-- the APPLY results schema table, and supply the new table as input to
-- RANK_APPLY. The only requirement is that the new column names have to be
-- reflected in the RANK_APPLY procedure. The table containing the ranked
-- results will reflect these new column names.
-- 
ALTER TABLE nb_sh_sample_apply_result RENAME COLUMN cust_id TO customer_id;
ALTER TABLE nb_sh_sample_apply_result RENAME COLUMN prediction TO score;
ALTER TABLE nb_sh_sample_apply_result RENAME COLUMN probability TO chance;

-- RANK APPLY RESULTS (WITH COST MATRIX INPUT)
--
BEGIN
  DBMS_DATA_MINING.RANK_APPLY (
    apply_result_table_name     => 'nb_sh_sample_apply_result',
    case_id_column_name         => 'customer_id',
    score_column_name           => 'score',
    score_criterion_column_name => 'chance',
    ranked_apply_table_name     => 'nb_sh_sample_apply_ranked',
    top_n                       => 2,
    cost_matrix_table_name      => 'nb_alter_cost');
END;
/

-- RANK_APPLY RESULT OBJECTS: nb_sh_sample_apply_ranked

-------------------------------
-- DISPLAY RANKED APPLY RESULTS
-- using altered cost matrix
column chance format 9.99
column cost format 9.99 
SELECT customer_id, score, ROUND(chance,4) chance, ROUND(cost,4) cost, rank
  FROM nb_sh_sample_apply_ranked
 WHERE customer_id <= 100005
 ORDER BY customer_id, rank;
