-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 23ai
-- 
--   Classification - Neural Networks Algorithm - dmnncdem.sql
--   
--   Copyright (c) 2024 Oracle Corporation and/or its affilitiates.
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
-- Given demographic and purchase data about a set of customers, predict
-- customer's response to an affinity card program using a NN classifier.
--

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-------
-- DATA
-------
-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).
--


-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with the same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('NNC_SH_Clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/


------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nnc_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nnc_sh_sample_class_wt';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- CREATE AND POPULATE A CLASS WEIGHTS TABLE
--
-- A class weights table is used to influence the weighting of target classes
-- during model creation. For example, weights of (0.9, 0.1) for a binary
-- problem specify that an error in the first class has significantly
-- higher penalty that an error in the second class. Weights of (0.5, 0.5)
-- do not introduce a differential weight and would produce the same
-- model as when no weights are provided.
--
CREATE TABLE nnc_sh_sample_class_wt (
  target_value NUMBER,
  class_weight NUMBER);
INSERT INTO nnc_sh_sample_class_wt VALUES (0,0.35);
INSERT INTO nnc_sh_sample_class_wt VALUES (1,0.65);
COMMIT;

-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE nnc_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
set echo on

--    
BEGIN 
-- Populate settings table
  INSERT INTO nnc_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.algo_name, dbms_data_mining.algo_neural_network);
  INSERT INTO nnc_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.clas_weights_table_name, 'nnc_sh_sample_class_wt');
  INSERT INTO nnc_sh_sample_settings (setting_name, setting_value) VALUES
  (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);

  -- Examples of other possible settings are:
  --(dbms_data_mining.odms_random_seed, '12');
  --(dbms_data_mining.nnet_hidden_layers, '2');
  --(dbms_data_mining.nnet_nodes_per_layer, '10, 30');
  --(dbms_data_mining.nnet_iterations, '100');
  --(dbms_data_mining.nnet_tolerance, '0.0001');
  --(dbms_data_mining.nnet_activations, 
  --   ''''|| dbms_data_mining.nnet_activations_log_sig ||'''');
  --(dbms_data_mining.nnet_regularizer, 
  --        dbms_data_mining.nnet_regularizer_heldaside);
  --(dbms_data_mining.nnet_heldaside_ratio, '0.3');
  --(dbms_data_mining.nnet_heldaside_max_fail, '5');
  --(dbms_data_mining.nnet_regularizer,
  --        dbms_data_mining.nnet_regularizer_l2);
  --(dbms_data_mining.nnet_reg_lambda, '0.5');
  --(dbms_data_mining.nnet_weight_upper_bound, '0.7');
  --(dbms_data_mining.nnet_weight_lower_bound, '-0.6')
  --(dbms_data_mining.lbfgs_history_depth, '20');
  --(dbms_data_mining.lbfgs_scale_hessian, 
  --        dbms_data_mining.lbfgs_scale_hessian_disable);
  --(dbms_data_mining.lbfgs_gradient_tolerance, '0.0001');
 
END;
/

---------------------
-- CREATE A NEW MODEL
--
-- Build a new SVM Model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'NNC_SH_Clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'nnc_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'NNC_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'NNC_SH_CLAS_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='NNC_SH_CLAS_SAMPLE'
  ORDER BY view_name;


-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------


------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--
-- The queries shown below demonstrate the use of SQL data mining functions
-- along with analytic functions to compute various test metrics. In these
-- queries:
--
-- Modelname:             nnc_sh_clas_sample
-- # of Lift Quantiles:   10
-- Target attribute:      affinity_card
-- Positive target value: 1
-- (Change these as appropriate for a different example)

-- Compute CONFUSION MATRIX
--
-- This query demonstates how to generate a confusion matrix using the
-- SQL prediction functions for scoring. The returned columns match the
-- schema of the table generated by COMPUTE_CONFUSION_MATRIX procedure.
--
SELECT affinity_card AS actual_target_value,
       PREDICTION(nnc_sh_clas_sample USING *) AS predicted_target_value,
       COUNT(*) AS value
  FROM mining_data_test_v
 GROUP BY affinity_card, PREDICTION(nnc_sh_clas_sample USING *)
 ORDER BY 1, 2;

-- Compute ACCURACY
--
column accuracy format 9.99

SELECT SUM(correct)/COUNT(*) AS accuracy
  FROM (SELECT DECODE(affinity_card,
                 PREDICTION(nnc_sh_clas_sample USING *), 1, 0) AS correct
          FROM mining_data_test_v);

-- Compute CUMULATIVE LIFT, GAIN Charts.
--
-- The cumulative gain chart is a popular version of the lift chart, and
-- it maps cumulative gain (Y axis) against the cumulative records (X axis).
--
-- The cumulative lift chart is another popular representation of lift, and
-- it maps cumulative lift (Y axis) against the cumulative records (X axis).
--
-- The query also returns the probability associated with each quantile, so
-- that when the cut-off point for Lift is selected, you can correlate it
-- with a probability value (say P_cutoff). You can then use this value of
-- P_cutoff in a prediction query as follows:
--
-- SELECT *
--   FROM records_to_be_scored
--  WHERE PREDICTION_PROBABILITY(svmc_sh_clas_sample, 1 USING *) > P_cutoff;
--
-- In the query below
--
-- q_num     - Quantile Number
-- pos_cnt   - # of records that predict the positive target
-- pos_prob  - the probability associated with predicting a positive target
--             value for a given new record
-- cume_recs - % Cumulative Records upto quantile
-- cume_gain - % Cumulative Gain
-- cume_lift - Cumulative Lift
--
-- Note that the LIFT can also be computed using 
-- DBMS_DATA_MINING.COMPUTE_LIFT function, see examples in dmnbdemo.sql.
--
WITH
pos_prob_and_counts AS (
SELECT PREDICTION_PROBABILITY(nnc_sh_clas_sample, 1 USING *) pos_prob,
       -- hit count for positive target value
       DECODE(affinity_card, 1, 1, 0) pos_cnt
  FROM mining_data_test_v
),
qtile_and_smear AS (
SELECT NTILE(10) OVER (ORDER BY pos_prob DESC) q_num,
       pos_prob,
       -- smear the counts across records with the same probability to
       -- eliminate potential biased distribution across qtl boundaries
       AVG(pos_cnt) OVER (PARTITION BY pos_prob) pos_cnt
  FROM pos_prob_and_counts
),
cume_and_total_counts AS (
SELECT q_num,
       -- inner sum for counts within q_num groups,
       -- outer sum for cume counts
       MIN(pos_prob) pos_prob,
       SUM(COUNT(*)) OVER (ORDER BY q_num) cume_recs,
       SUM(SUM(pos_cnt)) OVER (ORDER BY q_num) cume_pos_cnt,
       SUM(COUNT(*)) OVER () total_recs,
       SUM(SUM(pos_cnt)) OVER () total_pos_cnt
  FROM qtile_and_smear
 GROUP BY q_num
)
SELECT pos_prob,
       100*(cume_recs/total_recs) cume_recs,
       100*(cume_pos_cnt/total_pos_cnt) cume_gain,
       (cume_pos_cnt/total_pos_cnt)/(cume_recs/total_recs) cume_lift
  FROM cume_and_total_counts
 ORDER BY pos_prob DESC;

-- Compute ROC CURVE
--
-- This can be used to find the operating point for classification.
--
-- The ROC curve plots true positive fraction - TPF (Y axis) against
-- false positive fraction - FPF (X axis). Note that the query picks
-- only the corner points (top tpf switch points for a given fpf) and
-- the last point. It should be noted that the query does not generate
-- the first point, i.e (tpf, fpf) = (0, 0). All of the remaining points
-- are computed, but are then filtered based on the criterion above. For
-- example, the query picks points a,b,c,d and not points o,e,f,g,h,i,j. 
--
-- The Area Under the Curve (next query) is computed using the trapezoid
-- rule applied to all tpf change points (i.e. summing up the areas of
-- the trapezoids formed by the points for each segment along the X axis;
-- (recall that trapezoid Area = 0.5h (A+B); h=> hieght, A, B are sides).
-- In the example, this means the curve covering the area would trace
-- points o,e,a,g,b,c,d.
--
-- |
-- |        .c .j .d
-- |  .b .h .i
-- |  .g
-- .a .f
-- .e
-- .__.__.__.__.__.__
-- o
--
-- Note that the ROC curve can also be computed using 
-- DBMS_DATA_MINING.COMPUTE_ROC function, see examples in dmnbdemo.sql.
--
column prob format 9.9999
column fpf  format 9.9999
column tpf  format 9.9999

WITH
pos_prob_and_counts AS (
SELECT PREDICTION_PROBABILITY(nnc_sh_clas_sample, 1 USING *) pos_prob,
       -- hit count for positive target value
       DECODE(affinity_card, 1, 1, 0) pos_cnt
  FROM mining_data_test_v
),
cume_and_total_counts AS (
SELECT pos_prob,
       pos_cnt,
       SUM(pos_cnt) OVER (ORDER BY pos_prob DESC) cume_pos_cnt, 
       SUM(pos_cnt) OVER () tot_pos_cnt,
       SUM(1 - pos_cnt) OVER (ORDER BY pos_prob DESC) cume_neg_cnt,
       SUM(1 - pos_cnt) OVER () tot_neg_cnt
  FROM pos_prob_and_counts
),
roc_corners AS (
SELECT MIN(pos_prob) pos_prob,
       MAX(cume_pos_cnt) cume_pos_cnt, cume_neg_cnt,
       MAX(tot_pos_cnt) tot_pos_cnt, MAX(tot_neg_cnt) tot_neg_cnt
  FROM cume_and_total_counts
 WHERE pos_cnt = 1                      -- tpf switch points
    OR (cume_pos_cnt = tot_pos_cnt AND  -- top-right point 
        cume_neg_cnt = tot_neg_cnt)
 GROUP BY cume_neg_cnt
)
SELECT pos_prob prob,
       cume_pos_cnt/tot_pos_cnt tpf,
       cume_neg_cnt/tot_neg_cnt fpf,
       cume_pos_cnt tp,
       tot_pos_cnt - cume_pos_cnt fn,
       cume_neg_cnt fp,
       tot_neg_cnt - cume_neg_cnt tn
  FROM roc_corners
 ORDER BY fpf;


-- Compute AUC (Area Under the roc Curve)
--
-- See notes on ROC Curve and AUC computation above
--
column auc format 9.99

WITH
pos_prob_and_counts AS (
SELECT PREDICTION_PROBABILITY(nnc_sh_clas_sample, 1 USING *) pos_prob,
       DECODE(affinity_card, 1, 1, 0) pos_cnt
  FROM mining_data_test_v
),
tpf_fpf AS (
SELECT  pos_cnt,
       SUM(pos_cnt) OVER (ORDER BY pos_prob DESC) /
         SUM(pos_cnt) OVER () tpf,
       SUM(1 - pos_cnt) OVER (ORDER BY pos_prob DESC) /
         SUM(1 - pos_cnt) OVER () fpf
  FROM pos_prob_and_counts
),
trapezoid_areas AS (
SELECT 0.5 * (fpf - LAG(fpf, 1, 0) OVER (ORDER BY fpf, tpf)) *
        (tpf + LAG(tpf, 1, 0) OVER (ORDER BY fpf, tpf)) area
  FROM tpf_fpf
 WHERE pos_cnt = 1
    OR (tpf = 1 AND fpf = 1)
)
SELECT SUM(area) auc
  FROM trapezoid_areas;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------


-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- Find the 10 customers who live in Italy that are most likely 
-- to use an affinity card.
--
SELECT cust_id FROM
(SELECT cust_id, 
        rank() over (order by PREDICTION_PROBABILITY(nnc_sh_clas_sample, 1
                     USING *) DESC, cust_id) rnk
   FROM mining_data_apply_v
  WHERE country_name = 'Italy')
where rnk <= 10
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
  FROM mining_data_apply_v
 WHERE PREDICTION(nnc_sh_clas_sample USING *) = 1
GROUP BY cust_gender
ORDER BY cust_gender;

------------------
-- BUSINESS CASE 3
-- List ten customers (ordered by their id) along with their likelihood to
-- use or reject the affinity card (Note: while this example has a
-- binary target, such a query is useful in multi-class classification -
-- Low, Med, High for example).
--
column prediction format 9;
column probability format 9.999999999
column cost format 9.999999999
SELECT T.cust_id, S.prediction, S.probability
  FROM (SELECT cust_id,
               PREDICTION_SET(nnc_sh_clas_sample USING *) pset
          FROM mining_data_apply_v
         WHERE cust_id < 100011) T,
       TABLE(T.pset) S
ORDER BY cust_id, S.prediction;

------------------
-- BUSINESS CASE 4
-- Find customers whose profession is Tech Support
-- with > 75% likelihood of using the affinity card,
-- and explain the attributes which make them likely
-- to use an affinity card.
--
set long 20000
SELECT cust_id, PREDICTION_DETAILS(nnc_sh_clas_sample, 1 USING *) PD
  FROM mining_data_apply_v
 WHERE PREDICTION_PROBABILITY(nnc_sh_clas_sample, 1 USING *) > 0.75
       AND occupation = 'TechSup'
ORDER BY cust_id;

