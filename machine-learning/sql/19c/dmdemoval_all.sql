Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmardemo_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmardemo_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates an association model
Rem      using the Apriori algorithm
Rem      and data in the SH (Sales History) schema in the RDBMS.
Rem
Rem    NOTES
Rem      Refer to tmardemo.sql for detail
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    jiangzho    02/18/16 - fixed a typo involving SVM
Rem    xbarr       03/12/12 - updates for 12c
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 140
SET echo ON

-- ODM API accepts data both in relational (2D) form, and
-- transactional form for Association Rules.
-- Transactional data is the more common form of input for
-- this type of problem, so the demo shows examples of
-- processing transactional input.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- Cleanup old dataset for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP VIEW sales_trans_cust';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------
-- DATA
-------
-- The data for this sample is composed from a small subset of
-- sales transactions in the SH schema - listing the (multiple)
-- items bought by a set of customers with ids in the range
-- 100001-104500. Note that this data is based on customer id,
-- not "basket" id (as in the case of true market basket data).
-- But in either case, it can be useful to remove duplicate occurrences
-- (e.g. customer buys two cans of milk in the same visit, or buys
-- boxes of the same cereal in multiple, independent visits)
-- of items per customer or per basket, if what we care about
-- is just the presence/absence of a given item per customer/basket
-- id to compute the rules. Hence the DISTINCT in the view definition.
--
-- Market basket or sales datasets are transactional in nature,
-- and form fact tables in a typical data warehouse.
--
CREATE VIEW sales_trans_cust AS
SELECT DISTINCT cust_id, prod_name, prod_category
FROM (SELECT a.cust_id, b.prod_name, b.prod_category
        FROM sh.sales a, sh.products b
       WHERE a.prod_id = b.prod_id AND
             a.cust_id between 100001 AND 104500);

-----------
-- ANALYSIS
-----------
-- Association Rules in ODM works best on sparse data - i.e. data where
-- the average number of attributes/items associated with a given case is
-- a small percentage of the total number of possible attributes/items.
-- This is true of most market basket datasets where an average customer
-- purchases only a small subset of items from a fairly large inventory
-- in the store.
--
-- This section provides a rough outline of the analysis to be performed
-- on data used for Association Rules model build.
--
-- 1. Compute the cardinality of customer id and product (940, 14)
SELECT COUNT(DISTINCT cust_id) cc, COUNT(DISTINCT prod_name) cp
  FROM sales_trans_cust;

-- 2. Compute the density of data (21.31)
column density format a18
SELECT TO_CHAR((100 * ct)/(cc * cp), 99.99) density
  FROM (SELECT COUNT(DISTINCT cust_id) cc,
               COUNT(DISTINCT prod_name) cp,
               COUNT(*) ct
          FROM sales_trans_cust);

-- 3. Common items are candidates for removal during model build, because
--    if a majority of customers have bought those items, the resulting
--    rules do not have much value. Find out most common items. For example,
--    the query shown below determines that Mouse_Pad is most common (303).
--
--    Since the dataset is small, we will skip common item removal.
--
column prod_name format a40
SELECT prod_name, count(prod_name) cnt
  FROM sales_trans_cust
GROUP BY prod_name
ORDER BY cnt DESC, prod_name DESC;

-- 4. Compute the average number of products purchased per customer (2.98)
--    3 out of 11 corresponds to the density we computed earlier.
--
column avg_num_prod format a16
SELECT TO_CHAR(AVG(cp), 999.99) avg_num_prod
  FROM (SELECT COUNT(prod_name) cp
          FROM sales_trans_cust
        GROUP BY cust_id);

-----------------------------------------------------------------------
--         SAMPLE PROBLEM USING TRANSACTIONAL (pair/triple) INPUT
-----------------------------------------------------------------------

-- ODM API accepts data both in relational (2D) form and
-- transactional form for Association Rules.
--
-- The transactional input is a two column table of the form:
-- (transaction_id, item_id)
-- or a three column table of the form:
-- (transaction_id, item_id, item_value)
-- where we use the case_id to represent a transaction_id.
--
-- Example of a two column transactional table is:
-- (transaction_id, item_id)
-- (1, 1)
-- (1, 4)
-- (2, 2)
-- or
-- (1, 'apple')
-- (1, 'pear')
-- (2, 'banana')
--
-- Example of a three column transactional table is:
-- (transaction_id, item_id, item_value)
-- (1, 'apple', 2)
-- (1, 'banana', 4)
-- (2, 'apple', 1)
-- (2, 'banana', 2)
-- or
-- (1, 'wine', 'red')
-- (1, 'wine', 'white')
-- (1, 'cheese', 'swiss')
-- (2, 'cheese', 'provolone')
-- which allows you to treat different (item_id, item_val) pairings
-- for a given transaction essentially as different, unique items.
--

-----------------------------------------------------------------------
--                            TEST THE MODEL
-----------------------------------------------------------------------

-- Association rules do not have a predefined test metric.
--
-- Two indirect measures of modeling success are:
--
-- 1. Number of Rules generated: The optimal number of rules is
--    application dependent. In general, an overwhelming number of
--    rules is undesirable for user interpretation. More rules take
--    longer to compute, and also consume storage and CPU cycles.
--    You avoid too many rules by increasing the value for support.
--
-- 2. Relevance of rules
--    This can be determined only by user inspection of rules, since
--    it is application dependent. Ideally, we want to find rules with
--    high confidence and with non-obvious patterns. The value for
--    confidence is an indicator of the strength of the rule - so
--    you could set the confidence value high in conjunction with
--    support and see if you get high quality rules.
--
-- 3. Frequent itemsets provide an insight into co-occurrence of items.

-----------------------------------------------------------------------
--                            DISPLAY MODEL CONTENT
-----------------------------------------------------------------------

-------------------------------------------------------------
-- Display Top-10 Frequent Itemsets
--
break on itemset_id skip 1;
column item format a40
SELECT item, support, number_of_items
  FROM (SELECT I.attribute_subname AS item,
               F.support,
               F.number_of_items
          FROM TABLE(DBMS_DATA_MINING.GET_FREQUENT_ITEMSETS(
                       'AR_SH_SAMPLE',
                       10)) F,
               TABLE(F.items) I
        ORDER BY number_of_items, support, item);

----------------------------------------------------------
-- Display Top-10 Association Rules
--
SET line 300
column antecedent format a30
column consequent format a20
column supp format 9.999
column conf format 9.999
SELECT a.attribute_subname antecedent,
       c.attribute_subname consequent,
       rule_support supp,
       rule_confidence conf,
       row_number() over (partition by rule_id order by a.attribute_subname) piece
  FROM TABLE(DBMS_DATA_MINING.GET_ASSOCIATION_RULES('AR_SH_SAMPLE', 10)) T,
       TABLE(T.consequent) C,
       TABLE(T.antecedent) A
 ORDER BY conf DESC, supp DESC, piece;

Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmdtdemo_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmdtdemo_n.sql - Data Mining Decision Tree DEMO with NLS
Rem
Rem    DESCRIPTION
Rem      This script creates a classification model
Rem      using the Decision Tree algorithm
Rem      and data from the SH (Sales History) schema in the RDBMS.
Rem
Rem      This program uses the PREDICTION_* functions for model scoring.
Rem
Rem    NOTES
Rem      Refer to dmdtdemo.sql for detail.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xbarr       03/12/12 - updates for 12c
Rem    xbarr       01/17/12 - add prediction_details demo
Rem    amozes      05/26/11 - remove xdb pretty print
Rem    xbarr       10/25/10 - binary_double formatting
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem

SET serveroutput ON
SET trimspool ON
SET pages 10000
SET linesize 320
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
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).

-----------
-- ANALYSIS
-----------
-- These are the factors to consider for data analysis in decision trees:
--
-- 1. Missing Value Treatment for Predictors
--
--    See dmsvcdem.sql for a definition of missing values, and the
--    steps to be taken for missing value imputation.
--
--    Decision Tree implementation in ODM handles missing predictor
--    values (by penalizing predictors which have missing values)
--    and missing target values (by simply discarding records with
--    missing target values).
--
-- 2. Outlier Treatment for Predictors for Build data
--
--    See dmsvcdem.sql for a discussion on outlier treatment.
--    For ODM decision trees, outlier treatment is not really necessary.
--
-- 3. Binning high cardinality data
--    No data preparation for the types we accept is necessary - even
--    for high cardinality predictors.  Preprocessing to reduce the
--    cardinality (e.g., binning) can improve the performance of the build.
--
--------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'DT_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
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
  FROM mining_data_test_v
GROUP BY affinity_card, PREDICTION(DT_SH_Clas_sample USING *)
ORDER BY 1,2;

-- DISPLAY CONFUSION MATRIX APPLYING THE COST MATRIX
--
SELECT affinity_card AS actual_target_value, 
       PREDICTION(DT_SH_Clas_sample COST MODEL USING *) 
         AS predicted_target_value,
       COUNT(*) AS value
  FROM mining_data_test_v
GROUP BY affinity_card, PREDICTION(DT_SH_Clas_sample COST MODEL USING *)
ORDER BY 1,2;

-- DISPLAY ACCURACY WITHOUT APPLYING COST MATRIX
--
SELECT ROUND(SUM(correct)/COUNT(*),4) AS accuracy
  FROM (SELECT DECODE(affinity_card,
               PREDICTION(DT_SH_Clas_sample USING *), 1, 0) AS correct
          FROM mining_data_test_v);

-- DISPLAY ACCURACY APPLYING THE COST MATRIX
--
SELECT ROUND(SUM(correct)/COUNT(*),4) AS accuracy
  FROM (SELECT DECODE(affinity_card,
                 PREDICTION(DT_SH_Clas_sample COST MODEL USING *),
                 1, 0) AS correct
          FROM mining_data_test_v);

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

------------------
-- BUSINESS CASE 1
-- Find the 10 customers who live in Italy that are least expensive
-- to be convinced to use an affinity card.
--
SELECT cust_id FROM
(SELECT cust_id,
        rank() over (order by PREDICTION_COST(DT_SH_Clas_sample,
                     1 COST MODEL USING *) ASC, cust_id) rnk
   FROM mining_data_apply_v
  WHERE country_name = '~I~t~a~l~y')
where rnk <= 10
order by rnk;

------------------
-- BUSINESS CASE 2
-- Find the average age of customers who are likely to use an
-- affinity card.
-- Include the build-time cost matrix in the prediction.
-- Only take into account CUST_MARITAL_STATUS, EDUCATION, and
-- HOUSEHOLD_SIZE as predictors.
-- Break out the results by gender.
--
column cust_gender format a12
SELECT cust_gender, COUNT(*) AS cnt, ROUND(AVG(age)) AS avg_age
  FROM mining_data_apply_v
 WHERE PREDICTION(dt_sh_clas_sample COST MODEL
                 USING cust_marital_status, education, household_size) = 1
GROUP BY cust_gender
ORDER BY cust_gender;

------------------
-- BUSINESS CASE 3
-- List ten customers (ordered by their id) along with likelihood and cost
-- to use or reject the affinity card (Note: while this example has a
-- binary target, such a query is useful in multi-class classification -
-- Low, Med, High for example).
--
column prediction format 9;
column probability format 9.999999999
column cost format 9.999999999
SELECT T.cust_id, S.prediction, S.probability, S.cost
  FROM (SELECT cust_id,
               PREDICTION_SET(dt_sh_clas_sample COST MODEL USING *) pset
          FROM mining_data_apply_v
         WHERE cust_id < 100011) T,
       TABLE(T.pset) S
ORDER BY cust_id, S.prediction;

------------------
-- BUSINESS CASE 4
-- Find the segmentation (resulting tree node and rule) for customers who
-- work in Tech support and are under 25.
--
set long 20000
set line 300
set pagesize 100
column education format a30;
SELECT cust_id, education,
       PREDICTION_DETAILS(dt_sh_clas_sample USING *) prediction_details
  FROM mining_data_apply_v
 WHERE occupation = '~T~e~c~h~S~u~p' AND age < 25
ORDER BY cust_id;
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmdtxvlddemo_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmdtxvlddemo_n.sql - Sample program for the DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of cross-validation for evaluating
Rem      decision tree models when the amount of data available for training
Rem      and testing is relatively small. 
Rem
Rem      Cross validation is a generic technique, and can be utilized for
Rem      evaluating other algorithms as well with suitable modifications
Rem      to settings.
Rem
Rem    NOTES
Rem     Refer to dmdtxvlddemo.sql for details
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xbarr       03/14/12 - updates for 12c
Rem    mjaganna    02/10/05 - mjaganna_xvalidate_demo
Rem    mjaganna    01/28/05 - Created
Rem

SET SERVEROUTPUT ON
SET ECHO OFF
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
SET long 2000000000


Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmkmdemo_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmkmdemo_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates a clustering model
Rem      using the K-Means algorithm
Rem      and data in the SH (Sales History) schema in the RDBMS.
Rem
Rem    NOTES
Rem      Refer to dmkmdemo.sql for detail
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/13/12 - updates for 12c
Rem    xbarr       01/17/12 - add cluster_details demo
Rem    xbarr       12/01/10 - modified case 3 to remove type creation
Rem    xbarr       10/25/10 - binary_double formatting
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 140
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Segment the demographic data into 10 clusters and study the individual
-- clusters. 

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).
--

-----------
-- ANALYSIS
-----------
-- For clustering using KM, perform the following on mining data.
--
-- 1. Use Data Auto Preparation
--

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'KM_SH_CLUS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'KM_SH_CLUS_SAMPLE'
ORDER BY attribute_name;

-------------------------
-- DISPLAY MODEL METADATA
--
column mining_function format a20
column algorithm format a20
SELECT mining_function, algorithm
  FROM user_mining_models
 WHERE model_name = 'KM_SH_CLUS_SAMPLE';

------------------------
-- DISPLAY MODEL DETAILS
--
-- Cluster details are best seen in pieces - based on the kind of
-- associations and groupings that are needed to be observed.
--
-- CLUSTERS
-- For each cluster_id, provides the number of records in the cluster,
-- the parent cluster id, the level in the hierarchy, and dispersion -
-- which is a measure of the quality of the cluster, and computationally,
-- the sum of square errors.
-- Since centroid, histogram, and rule details are not being requested
-- here, specify 0,0,0 as arguments to the table function to reduce
-- the amount of work it needs to perform when fetching details.
--
SELECT id clu_id, record_count rec_cnt, parent, tree_level, dispersion
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_KM('KM_SH_Clus_sample',null,null,0,0,0))
 ORDER BY id;

-- TAXONOMY
--
SELECT T.id clu_id, C.id child_id
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_KM('KM_SH_Clus_sample',null,null,0,0,0)) T,
       TABLE(T.child) C
ORDER BY T.id, C.id;

-- CENTROIDS FOR LEAF CLUSTERS
-- For cluster_id 18, this output lists all the attributes that
-- constitute the centroid, with the mean (for numericals) or
-- mode (for categoricals), along with the variance from mean
--
column aname format a30
column mode_val format a60
SELECT T.id clu_id,
       C.attribute_name aname,
       C.mean mean_val,
       C.mode_value mode_val,
       C.variance variance
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_KM('KM_SH_Clus_sample',18,null,1,0,0)) T,
       TABLE(T.centroid) C
ORDER BY aname;

-- HISTOGRAM FOR ATTRIBUTE OF A LEAF CLUSTER
-- For cluster 18, provide the histogram for the AGE attribute.
--
SELECT T.id clu_id,
       H.attribute_name aname,
       H.lower_bound lower_b,
       H.upper_bound upper_b,
       H.count rec_cnt
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_KM('KM_SH_Clus_sample',18,'AGE',0,1,0)) T,
       TABLE(T.histogram) H
ORDER BY lower_b;

-- RULES FOR LEAF CLUSTERS
-- A rule_id corresponds to the associated cluster_id. The support
-- indicates the number of records (say M) that satisfies this rule.
-- This is an upper bound on the number of records that fall within
-- the bounding box defined by the rule. Each predicate in the rule
-- antecedent defines a range for an attribute, and it can be
-- interpreted as the side of a bounding box which envelops most of
-- the data in the cluster.
-- Confidence = M/N, where N is the number of records in the cluster
-- and M is the rule support defined as above.
--
SELECT T.id                   rule_id,
       T.rule.rule_support    support,
       T.rule.rule_confidence confidence
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_KM('KM_SH_Clus_sample',null,null,0,0,1)) T
ORDER BY T.id;

-- RULE DETAILS FOR LEAF CLUSTERS
-- Attribute level details of each rule/cluster id.
-- For an attribute, support (say M) indicates the number of records that 
-- fall in the attribute range specified in the rule antecedent where the
-- given attribute is not null. Confidence is a number between 0 and 1
-- that indicates how relevant this attribute is in distinguishing the 
-- the records in the cluster from all the records in the whole data. The
-- larger the number, more relevant the attribute.
-- 
-- The query shown below reverse-transforms the data to its original
-- values, since build data was normalized.
--
column aname format a25
column op format a3
column val format a60
column support format 9999
column confidence format 9.9999
SELECT T.id rule_id,
       A.attribute_name aname,
       A.conditional_operator op,
       NVL(A.attribute_str_value,
         ROUND(A.attribute_num_value,4)) val,
       A.attribute_support support,
       A.attribute_confidence confidence
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_KM('KM_SH_Clus_sample',null,null,0,0,2)) T,
       TABLE(T.rule.antecedent) A
 WHERE T.id < 3
ORDER BY 1, 2, 3, 4, 5, 6;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

-- There is no specific set of testing parameters for Clustering.
-- Examination and analysis of clusters is the main method to prove
-- the efficacy of a clustering model.
--

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-- For a descriptive mining function like Clustering, "Scoring" involves
-- providing the probability values for each cluster.

-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the count per cluster into which the customers in this
-- given dataset have been grouped.
--
SELECT CLUSTER_ID(km_sh_clus_sample USING *) AS clus, COUNT(*) AS cnt 
  FROM mining_data_apply_v
GROUP BY CLUSTER_ID(km_sh_clus_sample USING *)
ORDER BY cnt DESC;

------------------
-- BUSINESS CASE 2
-- List ten most representative (based on likelihood) customers of cluster 2
--
SELECT cust_id
FROM (SELECT cust_id, rank() over (order by prob desc, cust_id) rnk_clus2
  FROM (SELECT cust_id, CLUSTER_PROBABILITY(km_sh_clus_sample, 2 USING *) prob
          FROM mining_data_apply_v))
WHERE rnk_clus2 <= 10
order by rnk_clus2;

------------------
-- BUSINESS CASE 3
-- List the five most relevant attributes for likely cluster assignments
-- for customer id 101362 (> 20% likelihood of assignment).
--
column prob format 9.9999
set long 10000
SELECT S.cluster_id, probability prob,
       CLUSTER_DETAILS(km_sh_clus_sample, S.cluster_id, 5 using T.*) det
FROM
  (SELECT v.*, CLUSTER_SET(km_sh_clus_sample, NULL, 0.2 USING *) pset
    FROM mining_data_apply_v v
   WHERE cust_id = 101362) T,
  TABLE(T.pset) S
order by 2 desc;

------------------
-- BUSINESS CASE 4
--
-- List the 10 rows which are most anomalous as measured by their
-- distance from the cluster centroids.  A row which is far from
-- all cluster centroids may be anomalous.
--
SELECT cust_id
FROM (
  SELECT cust_id,
         rank() over
           (order by CLUSTER_DISTANCE(km_sh_clus_sample USING *) desc) rnk
    FROM mining_data_apply_v)
WHERE rnk <= 11
ORDER BY rnk;


-----------------------------------------------------------------------
--    BUILD and APPLY a transient model using analytic functions
-----------------------------------------------------------------------
-- In addition to creating a persistent model that is stored as a schema
-- object, models can be built and scored on data on the fly using
-- Oracle's analytic function syntax.

------------------
-- BUSINESS CASE 5
--
-- Segment customers into 4 groups based on common characteristics
-- and provide the segment assignments.  Note that this query does
-- not reference a pre-build clustering model, but rather it segment
-- the input data on the fly.  Rerunning the same query with different
-- input will result in a different segmentation.
-- Also provide the main reasons (attributes) why a given customer
-- is placed into a specific cluster.
-- Note that the where clause has to be placed outside of the inline
-- view so that the analytic function will build the clustering model
-- on all the data, and not just the selected customers.
--
select * from (
SELECT cust_id,
       CLUSTER_ID(INTO 4 USING *) OVER () cluster_id,
       CLUSTER_DETAILS(INTO 4 USING *) OVER () cluster_det
  FROM mining_data_apply_v)
WHERE cust_id <= 100010
order by 1;
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmnbdemo_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmnbdemo_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates a classification model
Rem      using the Naive Bayes algorithm
Rem      and data in the SH (Sales History) schema in the RDBMS. 
Rem
Rem    NOTES
Rem      Refer to dmnbdemo.sql for detail.
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/13/12 - updates for 12c
Rem    xbarr       01/17/12 - add prediction_details demo
Rem    xbarr       10/25/10 - binary_double formatting
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
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
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).

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
column tname format a14
column tval format a4
column pname format a40
column pval format a200
column priorp format 9.9999
column condp format 9.9999
SELECT T.prior_probability                                           priorp,
       C.conditional_probability                                      condp,
       T.target_attribute_name                                        tname,
       TO_CHAR(
       NVL(T.target_attribute_num_value,T.target_attribute_str_value)) tval,
       C.attribute_name                                               pname,
       NVL(C.attribute_str_value, C.attribute_num_value)               pval
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_NB('NB_SH_Clas_sample')) T,
       TABLE(T.conditionals) C
ORDER BY 1,2,3,4,5,6;

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
  FROM mining_data_apply_v;

-- APPLY MODEL ON TEST DATA
--
BEGIN
  DBMS_DATA_MINING.APPLY(
    model_name          => 'NB_SH_Clas_sample',
    data_table_name     => 'mining_data_apply_v',
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
    data_table_name     => 'mining_data_apply_v',
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
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmnmdemo_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmnmdemo_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates a feature extraction model
Rem      using the NMF algorithm
Rem      and data in the SH (Sales History) schema in the RDBMS.
Rem
Rem    NOTES
Rem      Refer to dmnmdemo.sql for detail.
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/14/12 - updates for 12c
Rem    xbarr       01/17/12 - add feature_details demo
Rem    xbarr       12/01/10 - modified case 3 to remove type objects creation
Rem    xbarr       10/25/10 - binary_double formatting
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 100
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic data about a set of customers, extract features
-- from the given dataset.
--

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'NMF_SH_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'NMF_SH_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- Each feature is a linear combination of the original attribute set;
-- the coefficients of these linear combinations are non-negative.
-- The model details return for each feature the coefficients
-- associated with each one of the original attributes. Categorical
-- attributes are described by (attribute_name, attribute_value) pairs.
-- That is, for a given feature, each distinct value of a categorical
-- attribute has its own coefficient.
--
column attribute_name format a20;
column attribute_value format a60;
SELECT F.feature_id,
       A.attribute_name,
       A.attribute_value,
       A.coefficient
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_NMF('NMF_SH_Sample')) F,
       TABLE(F.attribute_set) A
WHERE feature_id = 1
  AND attribute_name in ('AFFINITY_CARD','AGE','COUNTRY_NAME')
ORDER BY feature_id,attribute_name,attribute_value;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------
-- There is no specific set of testing parameters for feature extraction.
-- Examination and analysis of features is the main method to prove
-- the efficacy of an NMF model.
--

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
--
-- For a descriptive mining function like feature extraction, "Scoring"
-- involves providing the probability values for each feature.
-- During model apply, an NMF model maps the original data into the
-- new set of attributes (features) discovered by the model.
--

-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the features that correspond to customers in this dataset.
-- The feature that is returned for each row is the one with the
-- largest value based on the inputs for that row.
-- Count the number of rows that have the same "largest" feature value.
--
SELECT FEATURE_ID(nmf_sh_sample USING *) AS feat, COUNT(*) AS cnt
  FROM mining_data_apply_v
group by FEATURE_ID(NMF_SH_SAMPLE using *)
ORDER BY cnt DESC,FEAT DESC;

------------------
-- BUSINESS CASE 2
-- List top (largest) 3 features that represent a customer (100002).
-- Explain the attributes which most impact those features.
--
set line 120
column fid format 999
column val format 999.999
set long 20000
SELECT S.feature_id fid, value val,
       FEATURE_DETAILS(nmf_sh_sample, S.feature_id, 5 using T.*) det
FROM
  (SELECT v.*, FEATURE_SET(nmf_sh_sample, 3 USING *) fset
    FROM mining_data_apply_v v
   WHERE cust_id = 100002) T,
  TABLE(T.fset) S
order by 2 desc;
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmocdemo_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmocdemo_n.sql - o-cluster NLS demo for DBMS_DATA_MINING package
Rem
Rem    DESCRIPTION
Rem      This script creates a clustering model
Rem      using the O-Cluster algorithm
Rem      and data in SH (Sales History) schema in the RDBMS.
Rem
Rem    NOTES
Rem      Refer to dmocdemo.sql for detail
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/14/12 - updates for 12c
Rem    xbarr       01/10/12 - add cluster_details
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 120
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Segment the demographic data into 10 clusters and study the individual
-- clusters. Rank the clusters on probability.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).
--

-----------
-- ANALYSIS
-----------
-- For clustering using OC, perform the following on mining data.
--
-- 1. Use Data Auto Preparation
--    O-Cluster uses a special binning procedure that automatically
--    determines the number of bins based on data statistics.
--

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'OC_SH_CLUS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'OC_SH_CLUS_SAMPLE'
ORDER BY attribute_name;

-------------------------
-- DISPLAY MODEL METADATA
--
column mining_function format a20
column algorithm format a20
SELECT mining_function, algorithm
  FROM user_mining_models
 WHERE model_name = 'OC_SH_CLUS_SAMPLE';

------------------------
-- DISPLAY MODEL DETAILS
--
-- Cluster details are best seen in pieces - based on the kind of
-- associations and groupings that are needed to be observed.
--

-- CLUSTERS
-- For each cluster_id, provides the number of records in the cluster,
-- the parent cluster id, and the level in the hierarchy.
-- NOTE: Unlike K-means, O-Cluster does not return a value for the
--       dispersion associated with a cluster.
--
SELECT id clu_id, record_count rec_cnt, parent, tree_level, dispersion
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_OC('OC_SH_Clus_sample',null,null,0,0,0))
 ORDER BY id;

-- TAXONOMY
--
SELECT T.id clu_id, C.id child_id
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_OC('OC_SH_Clus_sample',null,null,0,0,0)) T,
       TABLE(T.child) C
ORDER BY T.id, C.id;

-- SPLIT PREDICATES
-- For each cluster, the split predicate indicates the attribute
-- and the condition used to assign records to the cluster's children
-- during model build. It provides an important piece of information
-- on how the population within a cluster can be divided up into
-- two smaller clusters.
--
column attribute_name format a20
column op format a2
column s_value format a50
SELECT a.id clu_id, sp.attribute_name, sp.conditional_operator op,
       sp.attribute_str_value s_value
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_OC('OC_SH_Clus_sample',null,null,0,0,0)) a,
       TABLE(a.split_predicate) sp
ORDER BY a.id, op, s_value;

-- CENTROIDS FOR LEAF CLUSTERS
-- For cluster_id 1, this output lists all the attributes that
-- constitute the centroid, with the mean (for numericals) or
-- mode (for categoricals). Unlike K-Means, O-Cluster does not return
-- the variance for numeric attributes.
--
column mode_value format a60
SELECT T.id clu_id,
       C.attribute_name,
       C.mean,
       C.mode_value
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_OC('OC_SH_Clus_sample',1,null,1,0,0)) T,
       TABLE(T.centroid) C
ORDER BY attribute_name;

-- HISTOGRAM FOR ATTRIBUTE OF A LEAF CLUSTER
-- For cluster 1, provide the histogram for the AGE attribute.
-- Histogram count is represented in frequency, rather than actual count.
column count format 9999.99
column bin_id format 9999999
column clu_id format 99999999
column label format a20;
SELECT a.id clu_id, h.bin_id, h.attribute_name, h.label, h.count cnt
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_OC('OC_SH_Clus_sample',1,'AGE',0,1,0)) a,
       TABLE(a.histogram) h
 ORDER BY a.id, h.attribute_name, h.bin_id;

-- RULES FOR LEAF CLUSTERS
-- See dmkmdemo.sql for explanation on output columns.
column confidence format 999999.99
SELECT T.id                   rule_id,
       T.rule.rule_support    support,
       T.rule.rule_confidence confidence
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_OC('OC_SH_Clus_sample',null,null,0,0,1)) T
ORDER BY T.id;

-- RULE DETAILS FOR LEAF CLUSTERS
-- See dmkmdemo.sql for explanation on output columns.
column aname format a25
column op format a3
column val format a60
column support format 9999
column confidence format 9.9999
SELECT T.id rule_id,
       A.attribute_name aname,
       A.conditional_operator op,
       NVL(A.attribute_str_value,
         ROUND(A.attribute_num_value,4)) val,
       A.attribute_support support,
       A.attribute_confidence confidence
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_OC('OC_SH_Clus_sample',null,null,0,0,2)) T,
       TABLE(T.rule.antecedent) A
 WHERE T.id < 3
ORDER BY 1, 2, 3, 4, 5, 6;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

-- There is no specific set of testing parameters for Clustering.
-- Examination and analysis of clusters is the main method to prove
-- the efficacy of a clustering model.
--

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-- For a descriptive mining function like Clustering, "Scoring" involves
-- assigning the probability with which a given case belongs to a given
-- cluster.

-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the clusters into which the customers in this
-- given dataset have been grouped.
--
SELECT CLUSTER_ID(oc_sh_clus_sample USING *) AS clus, COUNT(*) AS cnt
  FROM mining_data_apply_v
GROUP BY CLUSTER_ID(oc_sh_clus_sample USING *)
ORDER BY cnt DESC;

-- See dmkmdemo.sql for more examples

------------------
-- BUSINESS CASE 2
-- Assign 5 customers to clusters, and provide explanations for the assingments.
--
set long 20000
set line 200
set pagesize 100
column cust_id format 999999999
SELECT cust_id,
       cluster_details(oc_sh_clus_sample USING *) cluster_details
  FROM mining_data_apply_v
 WHERE cust_id <= 100005
 ORDER BY cust_id;
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmsvcdem_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmsvcdem_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates a classification model
Rem      using the SVM algorithm
Rem      and data in the SH (Sales History) schema in the RDBMS.
Rem
Rem    NOTES
Rem      This script demonstrates the use of the new Oracle
Rem      SQL functions for scoring models against new data, and
Rem      the computation of various test metrics based on these
Rem      new SQL functions.
Rem
Rem      Refer to dmsvcdem.sql for detail.
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/14/12 - updates for 12c
Rem    xbarr       01/17/12 - add prediction_details output
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic and purchase data about a set of customers, predict
-- customer's response to an affinity card program using an SVM classifier.
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
  
-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'SVMC_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'SVMC_SH_CLAS_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- The coefficient indicates the relative influence of a given
-- (attribute, value) pair on the target value. A negative
-- coefficient value indicates a negative influence.
--
-- NOTE: The row in the SVM model details output with a NULL attribute_name
-- shows the value for SVM bias under the COEFFICIENT column.
--
SET line 120
column class format a10
column aname format a30
column aval  format a30
column coeff format 9.99
SELECT D.class, A.attribute_name aname, A.attribute_value aval, A.coefficient coeff
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_SVM('SVMC_SH_Clas_sample')) D,
       TABLE(D.attribute_set) A
WHERE ABS(a.coefficient) > 0.01  
ORDER BY D.class, ABS(A.coefficient) DESC;

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
-- Modelname:             svmc_sh_clas_sample
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
       PREDICTION(svmc_sh_clas_sample USING *) AS predicted_target_value,
       COUNT(*) AS value
  FROM mining_data_test_v 
 GROUP BY affinity_card, PREDICTION(svmc_sh_clas_sample USING *)
 ORDER BY 1, 2;

-- Compute ACCURACY
--
column accuracy format 9.99

SELECT SUM(correct)/COUNT(*) AS accuracy
  FROM (SELECT DECODE(affinity_card,
                 PREDICTION(svmc_sh_clas_sample USING *), 1, 0) AS correct
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
SELECT PREDICTION_PROBABILITY(svmc_sh_clas_sample, 1 USING *) pos_prob,
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
SELECT PREDICTION_PROBABILITY(svmc_sh_clas_sample, 1 USING *) pos_prob,
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
SELECT PREDICTION_PROBABILITY(svmc_sh_clas_sample, 1 USING *) pos_prob,
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
        rank() over (order by PREDICTION_PROBABILITY(svmc_sh_clas_sample, 1
                     USING *) DESC, cust_id) rnk
   FROM mining_data_apply_v
  WHERE country_name = '~I~t~a~l~y')
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
 WHERE PREDICTION(svmc_sh_clas_sample USING *) = 1
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
               PREDICTION_SET(svmc_sh_clas_sample USING *) pset
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
SELECT cust_id, PREDICTION_DETAILS(svmc_sh_clas_sample, 1 USING *) PD
  FROM mining_data_apply_v
 WHERE PREDICTION_PROBABILITY(svmc_sh_clas_sample, 1 USING *) > 0.75
       AND occupation = '~T~e~c~h~S~u~p'
ORDER BY cust_id;

-----------------------------------------------------------------------
--    BUILD and APPLY a transient model using analytic functions
-----------------------------------------------------------------------
-- In addition to creating a persistent model that is stored as a schema
-- object, models can be built and scored on data on the fly using
-- Oracle's analytic function syntax.

----------------------
-- BUSINESS USE CASE 5
--
-- Identify rows that do not currently have an affinity card, but
-- the customer pattern is like those that do have such a card.
-- Perform this analysis by building a classification model on the
-- fly and scoring it against the same data, and extract those
-- customers who do not have a card, but are predicted to have a card
-- based on observed patterns.
-- All necessary data preparation steps are automatically performed.
col pred_prob format 9.99
select cust_id, pred_prob from
(select cust_id, affinity_card,
        prediction(for to_char(affinity_card) using *) over () pred_card,
        prediction_probability(for to_char(affinity_card),1 using *) over () pred_prob
 from mining_data_build_v)
where affinity_card = 0
  and pred_card = 1
order by pred_prob desc;
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmsvodem_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmsvodem_n.sql - Data Mining SVm One-class NLS DEMo program
Rem
Rem    DESCRIPTION
Rem      This script creates an anomaly detection model
Rem      for data analysis and outlier identification using the
Rem      one-class SVM algorithm
Rem      and data in the SH (Sales History)schema in the RDBMS.
Rem
Rem    NOTES
Rem      Refer to dmsvodem.sql for detail
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xbarr       03/14/12 - updates for 12c
Rem    xbarr       01/17/12 - add prediction_details demo
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographics about a set of customers that are known to have 
-- an affinity card, 1) find the most atypical members of this group 
-- (outlier identification), 2) discover the common demographic 
-- characteristics of the most typical customers with affinity card, 
-- and 3) compute how typical a given new/hypothetical customer is.
--
-------
-- DATA
-------
-- The data for this sample is composed from base tables in the SH schema
-- (See Sample Schema Documentation) and presented through a view:
-- mining_data_one_class_v
-- (See dmsh.sql for view definition).
--
--
-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'SVMO_SH_CLAS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
-- For sample code displaying SVM signature see dmsvcdem.sql.

------------------------
-- DISPLAY MODEL DETAILS
--
-- Model details are available only for SVM models with linear kernel.
-- For SVM model details sample code see dmsvcdem.sql.
--

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

-- Depending on the business case, the model can be scored against the
-- build data (e.g, business cases 1 and 2) or against new, previously
-- unseen data (e.g., business case 3). New apply data needs to undergo 
-- the same transformations as the build data (see business case 3).

------------------
-- BUSINESS CASE 1
-- Find the top 5 outliers - customers that differ the most from
-- the rest of the population. Depending on the application, such
-- atypical customers can be removed from the data (data cleansing).
-- Explain which attributes cause them to appear different.
--
set long 20000
col pd format a90
SELECT cust_id, pd FROM
(SELECT cust_id,
        PREDICTION_DETAILS(SVMO_SH_Clas_sample, 0 using *) pd,
        rank() over (order by prediction_probability(
                     SVMO_SH_Clas_sample, 0 using *) DESC, cust_id) rnk
 FROM mining_data_one_class_v)
WHERE rnk <= 5
order by rnk;

------------------
-- BUSINESS CASE 2
-- Find demographic characteristics of the typical affinity card members.
-- These statistics will not be influenced by outliers and are likely to
-- provide a more truthful picture of the population of interest than
-- statistics computed on the entire group of affinity members.
-- Statistics are computed on the original (non-transformed) data.
column cust_gender format a12
SELECT cust_gender, round(avg(age)) age,
       round(avg(yrs_residence)) yrs_residence,
       count(*) cnt
FROM mining_data_one_class_v
WHERE prediction(SVMO_SH_Clas_sample using *) = 1
GROUP BY cust_gender
ORDER BY cust_gender;


------------------
-- BUSINESS CASE 3
-- 
-- Compute probability of a new/hypothetical customer being a typical
-- affinity card holder.
-- Necessary data preparation on the input attributes is performed
-- automatically during model scoring since the model was build with
-- auto data prep.
--
column prob_typical format 9.99
select prediction_probability(SVMO_SH_Clas_sample, 1 using
                             44 AS age,
                             6 AS yrs_residence,
                             '~B~a~c~h.' AS education,
                             '~M~a~r~r~i~e~d' AS cust_marital_status,
                             '~E~x~e~c.' AS occupation,
                             '~U~n~i~t~e~d ~S~t~a~t~e~s ~o~f ~A~m~e~r~i~c~a' AS country_name,
                             'M' AS cust_gender,
                             '~L: 300,000 and above' AS cust_income_level,
                             '3' AS household_size
                             ) prob_typical
from dual;

-----------------------------------------------------------------------
--    BUILD and APPLY a transient model using analytic functions
-----------------------------------------------------------------------
-- In addition to creating a persistent model that is stored as a schema
-- object, models can be built and scored on data on the fly using
-- Oracle's analytic function syntax.

----------------------
-- BUSINESS USE CASE 4
--
-- Identify rows that are most atypical in the input dataset.
-- Consider each type of marital status to be separate, so the most
-- anomalous rows per marital status group should be returned.
-- Provide the top three attributes leading to the reason for the
-- record being an anomaly.
-- The partition by clause used in the analytic version of the
-- prediction_probability function will lead to separate models
-- being built and scored for each marital status.
col cust_marital_status format a30
select cust_id, cust_marital_status, rank_anom, anom_det FROM
(SELECT cust_id, cust_marital_status, anom_det,
        rank() OVER (PARTITION BY CUST_MARITAL_STATUS
                     ORDER BY ANOM_PROB DESC,cust_id) rank_anom FROM
 (SELECT cust_id, cust_marital_status,
        PREDICTION_PROBABILITY(OF ANOMALY, 0 USING *)
          OVER (PARTITION BY CUST_MARITAL_STATUS) anom_prob,
        PREDICTION_DETAILS(OF ANOMALY, 0, 3 USING *)
          OVER (PARTITION BY CUST_MARITAL_STATUS) anom_det
   FROM mining_data_one_class_v
 ))
where rank_anom < 3 order by 2, 3;
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmsvrdem_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmsvrdem_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates a regression model
Rem      using the SVM algorithm
Rem      and data in the SH (Sales History) schema in the RDBMS.
Rem
Rem    NOTES
Rem      Refer to dmsvrdem.sql for detail.
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/14/12 - updates for 12c
Rem    xbarr       01/17/12 - add prediction_details demo
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic, purchase, and affinity card membership data for a 
-- set of customers, predict customer's age. Since age is a continuous 
-- variable, this is a regression problem.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in the SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).
--
-----------
-- ANALYSIS
-----------
-- For regression using SVM, perform the following on mining data.
--
-- 1. Use Auto Data Preparation
--

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'SVMR_SH_REGR_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
col attribute_name format a30
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'SVMR_SH_REGR_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
-- Skip. GET_MODEL_DETAILS_SVM is supported only for Linear Kernels.
-- The current model is built using a Gaussian Kernel (see dmsvcdem.sql).
--

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

------------------------------------
-- COMPUTE METRICS TO TEST THE MODEL
--

-- 1. Root Mean Square Error - Sqrt(Mean((y - y')^2))
--
column rmse format 9999.99
SELECT SQRT(AVG((prediction - age) * (prediction - age))) rmse
  FROM (select age, PREDICTION(svmr_sh_regr_sample USING *) prediction
        from mining_data_test_v);

-- 2. Mean Absolute Error - Mean(|(y - y')|)
--
column mae format 9999.99
SELECT AVG(ABS(prediction - age)) mae
  FROM (select age, PREDICTION(svmr_sh_regr_sample USING *) prediction
        from mining_data_test_v);

-- 3. Residuals
--    If the residuals show substantial variance between
--    the predicted value and the actual, you can consider
--    changing the algorithm parameters.
--
column prediction format 99.9999
SELECT prediction, (prediction - age) residual
  FROM (select age, PREDICTION(svmr_sh_regr_sample USING *) prediction
        from mining_data_test_v)
 WHERE prediction < 17.5
 ORDER BY prediction;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- Predict the average age of customers, broken out by gender.
--
column cust_gender format a12
SELECT A.cust_gender,
       COUNT(*) AS cnt,
       ROUND(
       AVG(PREDICTION(svmr_sh_regr_sample USING A.*)),4)
       AS avg_age
  FROM mining_data_apply_v A
GROUP BY cust_gender
ORDER BY cust_gender;

------------------
-- BUSINESS CASE 2
-- Create a 10 bucket histogram of customers from Italy based on their age
-- and return each customer's age group.
--
column pred_age format 999.99
SELECT cust_id,
       PREDICTION(svmr_sh_regr_sample USING *) pred_age,
       WIDTH_BUCKET(
        PREDICTION(svmr_sh_regr_sample USING *), 10, 100, 10) "Age Group"
  FROM mining_data_apply_v
 WHERE country_name = '~I~t~a~l~y'
ORDER BY pred_age;

------------------
-- BUSINESS CASE 3
-- Find the reasons (8 attributes with the most impact) for the
-- predicted age of customer 100001.
--
set long 2000
set line 200
set pagesize 100
SELECT PREDICTION_DETAILS(svmr_sh_regr_sample, null, 8 USING *) prediction_details
  FROM mining_data_apply_v
 WHERE cust_id = 100001;

-----------------------------------------------------------------------
--    BUILD and APPLY a transient model using analytic functions
-----------------------------------------------------------------------
-- In addition to creating a persistent model that is stored as a schema
-- object, models can be built and scored on data on the fly using
-- Oracle's analytic function syntax.

----------------------
-- BUSINESS USE CASE 4
--
-- Identify rows for which the provided value of the age column
-- does not match the expected value based on patterns in the data.
-- This could indicate bad data entry.
-- All necessary data preparation steps are automatically performed.
-- In addition, provide information as to what attributes most effect the
-- predicted value, where positive weights are pushing towards a larger
-- age and negative weights towards a smaller age.
set long 2000
set pagesize 100
col age_diff format 99.99
select cust_id, age, pred_age, age-pred_age age_diff, pred_det from
(select cust_id, age, pred_age, pred_det,
        rank() over (order by abs(age-pred_age) desc) rnk from
 (select cust_id, age,
         prediction(for age using *) over () pred_age,
         prediction_details(for age ABS using *) over () pred_det
  from mining_data_apply_v))
where rnk <= 5;
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmtxtsvm_n.sql
Rem
Rem Copyright (c) 2005, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmtxtsvm_n.sql - Sample NLS program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates a text mining model using
Rem      SVM classification function.
Rem
Rem    NOTES
Rem      Refer to dmtxtsvm.sql for detail.
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/14/12 - updates for 12c
Rem    jcjeon      09/10/08 - sync testcase with SB
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
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
-- Note how several text terms extracted from the COMMENTs documents
-- show up as influential predictors.
--
SET line 120
column class format a10
column attribute_name format a25
column attribute_subname format a25
column attribute_value format a25
column coefficient format 9.99
SELECT * from
(SELECT d.class, a.attribute_name, a.attribute_subname,
        a.attribute_value, a.coefficient,
        rank() over (order by abs(coefficient) desc) rnk
   FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_SVM('T_SVM_Clas_sample')) d,
        TABLE(d.attribute_set) a)
WHERE rnk <= 10
ORDER BY rnk;

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
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmtxtnmf_n.sql
Rem
Rem Copyright (c) 2008, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmtxtnmf_n.sql - Sample NLS program for the DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates a text mining model
Rem      using non-negative matrix factorization.
Rem
Rem    NOTES
Rem      Refer dmtxtnmf.sql for detail
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       03/14/12 - updates for 12c
Rem    jcjeon      09/10/08 - Created
Rem
  
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


-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30;
column setting_value format a30;
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'T_NMF_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'T_NMF_SAMPLE'
ORDER BY attribute_name;

------------------------
-- DISPLAY MODEL DETAILS
--
column attribute_name format a30;
column attribute_value format a20;
column coefficient format 9.99999;
set pages 15;
SET line 120;
break ON feature_id;
SELECT * FROM (
SELECT t.feature_id,
       nvl2(a.attribute_subname,
            a.attribute_name||'.'||a.attribute_subname,
            a.attribute_name) attribute_name,
       a.attribute_value,
       a.coefficient
  FROM TABLE(dbms_data_mining.get_model_details_nmf('T_NMF_Sample')) t,
       TABLE(t.attribute_set) a
WHERE feature_id < 3
ORDER BY 1,2,3,4)
WHERE ROWNUM < 21;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-- See dmnmdemo.sql for examples. 
Rem
Rem $Header: tk_datamining/tmdm/sql/dmdemoval_all.sql /main/2 2016/02/20 11:33:59 jiangzho Exp $
Rem
Rem dmemdemo_n.sql
Rem
Rem Copyright (c) 2011, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmemdemo_n.sql - Expectation Maximization DEMO nls sample
Rem
Rem    DESCRIPTION
Rem      NLS test using the EM demo code. Refer to dmemdemo.sql for details
Rem
Rem    NOTES
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xbarr       03/12/12 - updates for 12c
Rem    xbarr       01/17/12 - Add cluster_details demo
Rem    bmilenov    10/13/11 - bug-13083060: introduce approximate computation
Rem                           in EM
Rem    bmilenov    09/26/11 - NLS sample EM program
Rem    bmilenov    09/26/11 - Created
Rem

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 140
SET echo ON
  
-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Segment the demographic data into 10 clusters and study the individual
-- clusters.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- The data for this sample is composed from base tables in SH Schema
-- (See Sample Schema Documentation) and presented through these views:
-- mining_data_build_v (build data)
-- mining_data_test_v  (test data)
-- mining_data_apply_v (apply data)
-- (See dmsh.sql for view definitions).
--

-----------
-- ANALYSIS
-----------
-- For clustering using EM, perform the following on mining data.
--
-- 1. Use Data Auto Preparation
--

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'EM_SH_CLUS_SAMPLE'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'EM_SH_CLUS_SAMPLE'
ORDER BY attribute_name;

-------------------------
-- DISPLAY MODEL METADATA
--
column mining_function format a20
column algorithm format a30
SELECT mining_function, algorithm
  FROM user_mining_models
 WHERE model_name = 'EM_SH_CLUS_SAMPLE';

------------------------
-- DISPLAY MODEL DETAILS
--
-- Cluster details are best seen in pieces - based on the kind of
-- associations and groupings that are needed to be observed.
--
-- CLUSTERS
-- For each cluster_id, provides the number of records in the cluster,
-- the parent cluster id, the level in the hierarchy, and dispersion -
-- which is a measure of the quality of the cluster, and computationally,
-- the sum of square errors.
--
SELECT id           clu_id,
       record_count rec_cnt,
       parent       parent,
       tree_level   tree_level
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_EM('EM_SH_Clus_sample',null,null,0,0,0))
 ORDER BY id;

-- TAXONOMY
--
SELECT T.id clu_id, C.id child_id
 FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_EM('EM_SH_Clus_sample',null,null,0,0,0)) T,
      TABLE(T.child) C
 ORDER BY T.id, C.id;

-- CENTROIDS FOR LEAF CLUSTERS
-- For cluster_id 17, this output lists all the attributes that
-- constitute the centroid, with the mean (for numericals) or
-- mode (for categoricals), along with the variance from mean
--
column aname format a25
column mode_val format a20
column mean_val format 999999999.999
column variance format 999999999.999
SELECT T.id clu_id,
       C.attribute_name aname,
       C.mean mean_val,
       C.mode_value mode_val,
       C.variance variance
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_EM('EM_SH_Clus_sample',17,null,1,0,0)) T,
       TABLE(T.centroid) C
ORDER BY C.attribute_name;

-- HISTOGRAM FOR ATTRIBUTE OF A LEAF CLUSTER
-- For cluster 17, provide the histogram for the AGE attribute.
--
SELECT T.id clu_id,
       H.attribute_name aname,
       H.lower_bound lower_b,
       H.upper_bound upper_b,
       H.count rec_cnt
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_EM('EM_SH_Clus_sample',17,'AGE',0,1,0)) T,
       TABLE(T.histogram) H
 ORDER BY H.attribute_name, H.label;

-- RULES FOR LEAF CLUSTERS
-- A rule_id corresponds to the associated cluster_id. The support
-- indicates the number of records (say M) that satisfies this rule.
-- This is an upper bound on the  number of records that fall within
-- the bounding box defined by the rule. Each predicate in the rule
-- antecedent defines a range for an attribute, and it can be
-- interpreted as the side of a bounding box which envelops most of
-- the data in the cluster.
-- Confidence = M/N, where N is the number of records in the cluster
-- and M is the rule support defined as above.
--
SELECT T.id                   rule_id,
       T.rule.rule_support    support,
       T.rule.rule_confidence confidence
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_EM('EM_SH_Clus_sample',null,null,0,0,1)) T
ORDER BY T.id;

-- RULE DETAILS FOR LEAF CLUSTERS
-- Attribute level details of each rule/cluster id.
-- For an attribute, support (say M) indicates the number of records that 
-- fall in the attribute range specified in the rule antecedent where the
-- given attribute is not null. Confidence is a number between 0 and 1
-- that indicates how relevant this attribute is in distinguishing the 
-- the records in the cluster from all the records in the whole data. The
-- larger the number, more relevant the attribute.
-- 
-- The query shown below reverse-transforms the data to its original
-- values, since build data was normalized.
--
column aname format a25
column op format a3
column val format a20
column support format 9999
column confidence format 9.999
SELECT T.id rule_id,
       A.attribute_name aname,
       A.conditional_operator op,
       NVL(A.attribute_str_value,
         ROUND(A.attribute_num_value,4)) val,
       A.attribute_support support,
       A.attribute_confidence confidence
  FROM TABLE(DBMS_DATA_MINING.GET_MODEL_DETAILS_EM('EM_SH_Clus_sample',null,null,0,0,2)) T,
       TABLE(T.rule.antecedent) A
 WHERE T.id < 3
ORDER BY T.id, A.attribute_name, support, confidence desc, val, op;


-- Global EM model statistics
-- This API returns several high-level model statistics:
-- number of components, number of clusters, and log likelihood value
column global_detail_value format 9999999.999
select * from 
    table(dbms_data_mining.get_model_details_global('EM_SH_Clus_sample'))
ORDER BY global_detail_name;

-- EM component details
-- This API returns details about the EM component parameters.
-- The parameters include:
-- 1. Priors
-- 2. Means and variances for attributes modeled with Gaussian distributions
-- 3. Frequences for attributes modeled with multivalued Bernoulli 
--    distributions
-- This API also provides the mapping between components and leaf clusters
column info_type format a10
column attribute_name format a25
column covariate_name format a25
column attribute_value format a15 
column VALUE format 9999999.999
select * from 
    table(dbms_data_mining.get_model_details_em_comp('EM_SH_Clus_sample'))
WHERE component_id=11    
ORDER BY info_type, component_id, attribute_name, covariate_name,
attribute_value;

-----------------------------------------------------------------------
--                               TEST THE MODEL
-----------------------------------------------------------------------

-- There is no specific set of testing parameters for Clustering.
-- Examination and analysis of clusters is the main method to prove
-- the efficacy of a clustering model.
--

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-- For a descriptive mining function like Clustering, "Scoring" involves
-- providing the probability values for each cluster.

-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the clusters into which the customers in this
-- given dataset have been grouped.
--
SELECT CLUSTER_ID(em_sh_clus_sample USING *) AS clus, COUNT(*) AS cnt 
  FROM mining_data_apply_v
GROUP BY CLUSTER_ID(em_sh_clus_sample USING *)
ORDER BY cnt DESC;

------------------
-- BUSINESS CASE 2
-- List ten most representative (based on likelihood) customers of cluster 7
--
SELECT cust_id
FROM (SELECT cust_id, rank() over (order by prob desc, cust_id) rnk_clus2
  FROM (SELECT cust_id,
          round(CLUSTER_PROBABILITY(em_sh_clus_sample, 7 USING *),3) prob
          FROM mining_data_apply_v))
WHERE rnk_clus2 <= 10
order by rnk_clus2;

------------------
-- BUSINESS CASE 3
-- List the five most relevant attributes for likely cluster assignments
-- for customer id 100955 (> 20% likelihood of assignment).
--
column prob format 9.9999
set long 10000
SELECT S.cluster_id, probability prob,
       CLUSTER_DETAILS(em_sh_clus_sample, S.cluster_id, 5 using T.*) det
FROM
  (SELECT v.*, CLUSTER_SET(em_sh_clus_sample, NULL, 0.2 USING *) pset
    FROM mining_data_apply_v v
   WHERE cust_id = 100955) T,
  TABLE(T.pset) S
order by 2 desc;


select
PNAME
,ANTECEDENT_ATTRIBUTE_NAME aan
,ANTECEDENT_SUBNAME asn
,ANTECEDENT_VALUE anv
,CONSEQUENT_VALUE cnv
,LOG_CONDITIONAL_PROBABILITY lcp
,LOG_CONSEQUENT_COUNT lcc
,COUNT c
from DM$P0MODNB_PART
order by 1,2,3,4;

select
PNAME
,ATTRIBUTE_NAME aan
,VALUE anv
,LOG_PRIOR lp
,COUNT c
from DM$P1MODNB_PART
order by 1,2,3;

select
PNAME
,NVAL
,ATTR aan
,SUBN asn
,SVAL av
from DM$PEMODNB_PART
order by 1,2,3;

select
PNAME
,COL aan
,ATT asn
,NVAL
,CVAL av
,bin b
from DM$PNMODNB_PART
order by 1,2,3,5;

select
PNAME
,TYPE
,NAME asn
,NVAL
,SVAL av
from DM$PPMODNB_PART
order by 1,2;



exec dm_drop_table('MINING_DATA_APPLY_SMALL_NB');
create table MINING_DATA_APPLY_SMALL_NB as
select * from (
select m.*, row_number () over (partition by cust_marital_status order by cust_id, cust_marital_status) rown
from MBALL m order by ora_hash(m.cust_id))
where rown <=2;



exec dm_drop_table('MINING_DATA_APPLY_NB');
create table MINING_DATA_APPLY_NB as
select * from MBALL;

exec dm_drop_table('nb_pall_cost');
create table nb_pall_cost (
  actual_target_value           NUMBER,
  predicted_target_value        NUMBER,
  cost                          NUMBER);
insert into nb_pall_cost values (0, 0, 0);
insert into nb_pall_cost values (0, 1, 8);
insert into nb_pall_cost values (1, 0, 1);
insert into nb_pall_cost values (1, 1, 0);
commit;

exec dm_drop_table('nb_p1_cost');

create table nb_p1_cost (
  actual_target_value           NUMBER,
  predicted_target_value        NUMBER,
  cost                          NUMBER);
insert into nb_p1_cost values (0, 0, 0);
insert into nb_p1_cost values (0, 1, 6);
insert into nb_p1_cost values (1, 0, 2);
insert into nb_p1_cost values (1, 1, 0);
commit;

select cust_id, affinity_card, cust_marital_status,
           prediction_probability(/*+ GROUPING */ nb_pall using *) probability
     from mining_data_apply_small_nb t
    order by cust_id;


select cust_id, affinity_card, cust_marital_status,
          prediction_probability(nb_pall using *) probability
      from mining_data_apply_small_nb t
    order by cust_id;

 
select cust_id, affinity_card, cust_marital_status,
           prediction_probability(nb_p0 using *) probability
      from mining_data_apply_small_nb t
    order by cust_id;

select cust_id, affinity_card, cust_marital_status,
           prediction_probability(nb_pall using *) probability,
           ora_dm_partition_name(nb_pall using *) partition_name
      from mining_data_apply_small_nb t
    order by cust_id;

-- ORA_DM_PARTITION_NAME
select cust_id, cust_marital_status, ora_dm_partition_name(nb_pall using *) partition_name
    from mining_data_apply_small_nb
    order by cust_id;

exec dm_drop_table('NB_PALL_APPLY_RESULT');
exec dbms_data_mining.apply('NB_PALL', 'MINING_DATA_APPLY_NB', 'CUST_ID','NB_PALL_APPLY_RESULT');

select * from NB_PALL_APPLY_RESULT
    where cust_id<=101504
    order by cust_id, probability desc;

-- COMPUTE_CONFUSION_MATRIX (BY PARTITION)
CREATE OR REPLACE VIEW NB_PALL_TEST_TARGETS AS
SELECT cust_id, affinity_card
  FROM MINING_DATA_APPLY_NB;

exec dm_drop_table('NB_PALL_CONFUSION_MATRIX');
set serveroutput on
declare
  v_accuracy dm_nested_numericals;
  i number;
begin
  dbms_data_mining.compute_confusion_matrix_part(
    accuracy                    => v_accuracy,
    apply_result_table_name     => 'NB_PALL_APPLY_RESULT',
    target_table_name           => 'NB_PALL_TEST_TARGETS',
    case_id_column_name         => 'cust_id',
    target_column_name          => 'affinity_card',
    confusion_matrix_table_name => 'NB_PALL_CONFUSION_MATRIX',
    score_column_name           => 'PREDICTION',
    score_criterion_column_name => 'PROBABILITY',
    score_partition_column_name => 'PARTITION_NAME');
  for i in 1..v_accuracy.COUNT loop
    dbms_output.put_line(i||' '||v_accuracy(i).attribute_name || ' '|| round(v_accuracy(i).value,3));
  end loop;
end;
/


column value format 9999
column partition_name format a18
select * from NB_PALL_CONFUSION_MATRIX order by 1,2,4;


select
PNAME
,ANTECEDENT_ATTRIBUTE_NAME aan
,ANTECEDENT_SUBNAME asn
,ANTECEDENT_VALUE anv
,CONSEQUENT_VALUE cnv
,LOG_CONDITIONAL_PROBABILITY lcp
,LOG_CONSEQUENT_COUNT lcc
,COUNT c
from DM$P0MODNB_PART
order by 1,2,3,4;

select
PNAME
,ATTRIBUTE_NAME aan
,VALUE anv
,LOG_PRIOR lp
,COUNT c
from DM$P1MODNB_PART
order by 1,2,3;

select
PNAME
,NVAL
,ATTR aan
,SUBN asn
,SVAL av
from DM$PEMODNB_PART
order by 1,2,3;

select
PNAME
,COL aan
,ATT asn
,NVAL
,CVAL av
,bin b
from DM$PNMODNB_PART
order by 1,2,3,5;

select
PNAME
,TYPE
,NAME asn
,NVAL
,SVAL av
from DM$PPMODNB_PART
order by 1,2;



exec dm_drop_table('MINING_DATA_APPLY_SMALL_NB');
create table MINING_DATA_APPLY_SMALL_NB as
select * from (
select m.*, row_number () over (partition by cust_marital_status order by cust_id, cust_marital_status) rown
from MBALL m order by ora_hash(m.cust_id))
where rown <=2;



exec dm_drop_table('MINING_DATA_APPLY_NB');
create table MINING_DATA_APPLY_NB as
select * from MBALL;

exec dm_drop_table('nb_pall_cost');
create table nb_pall_cost (
  actual_target_value           NUMBER,
  predicted_target_value        NUMBER,
  cost                          NUMBER);
insert into nb_pall_cost values (0, 0, 0);
insert into nb_pall_cost values (0, 1, 8);
insert into nb_pall_cost values (1, 0, 1);
insert into nb_pall_cost values (1, 1, 0);
commit;

exec dm_drop_table('nb_p1_cost');

create table nb_p1_cost (
  actual_target_value           NUMBER,
  predicted_target_value        NUMBER,
  cost                          NUMBER);
insert into nb_p1_cost values (0, 0, 0);
insert into nb_p1_cost values (0, 1, 6);
insert into nb_p1_cost values (1, 0, 2);
insert into nb_p1_cost values (1, 1, 0);
commit;

select cust_id, affinity_card, cust_marital_status,
           prediction_probability(/*+ GROUPING */ nb_pall using *) probability
     from mining_data_apply_small_nb t
    order by cust_id;


select cust_id, affinity_card, cust_marital_status,
          prediction_probability(nb_pall using *) probability
      from mining_data_apply_small_nb t
    order by cust_id;

 
select cust_id, affinity_card, cust_marital_status,
           prediction_probability(nb_p0 using *) probability
      from mining_data_apply_small_nb t
    order by cust_id;

select cust_id, affinity_card, cust_marital_status,
           prediction_probability(nb_pall using *) probability,
           ora_dm_partition_name(nb_pall using *) partition_name
      from mining_data_apply_small_nb t
    order by cust_id;

-- ORA_DM_PARTITION_NAME
select cust_id, cust_marital_status, ora_dm_partition_name(nb_pall using *) partition_name
    from mining_data_apply_small_nb
    order by cust_id;

exec dm_drop_table('NB_PALL_APPLY_RESULT');
exec dbms_data_mining.apply('NB_PALL', 'MINING_DATA_APPLY_NB', 'CUST_ID','NB_PALL_APPLY_RESULT');

select * from NB_PALL_APPLY_RESULT
    where cust_id<=101504
    order by cust_id, probability desc;

-- COMPUTE_CONFUSION_MATRIX (BY PARTITION)
CREATE OR REPLACE VIEW NB_PALL_TEST_TARGETS AS
SELECT cust_id, affinity_card
  FROM MINING_DATA_APPLY_NB;

exec dm_drop_table('NB_PALL_CONFUSION_MATRIX');
set serveroutput on
declare
  v_accuracy dm_nested_numericals;
  i number;
begin
  dbms_data_mining.compute_confusion_matrix_part(
    accuracy                    => v_accuracy,
    apply_result_table_name     => 'NB_PALL_APPLY_RESULT',
    target_table_name           => 'NB_PALL_TEST_TARGETS',
    case_id_column_name         => 'cust_id',
    target_column_name          => 'affinity_card',
    confusion_matrix_table_name => 'NB_PALL_CONFUSION_MATRIX',
    score_column_name           => 'PREDICTION',
    score_criterion_column_name => 'PROBABILITY',
    score_partition_column_name => 'PARTITION_NAME');
  for i in 1..v_accuracy.COUNT loop
    dbms_output.put_line(i||' '||v_accuracy(i).attribute_name || ' '|| round(v_accuracy(i).value,3));
  end loop;
end;
/


column value format 9999
column partition_name format a18
select * from NB_PALL_CONFUSION_MATRIX order by 1,2,4;

--@tmnbparq
