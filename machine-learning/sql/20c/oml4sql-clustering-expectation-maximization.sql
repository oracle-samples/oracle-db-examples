-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   Clustering - Expectation-Maximization Algorithm - dmemdemo.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
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
-- mining_data_build_parallel_v (build data)
-- mining_data_test_parallel_v  (test data)
-- mining_data_apply_parallel_v (apply data)
-- (See dmsh.sql for view definitions).
--

-----------
-- ANALYSIS
-----------
-- For clustering using EM, perform the following on mining data.
--
-- 1. Use Data Auto Preparation
--

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('EM_SH_Clus_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE em_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- K-Means is the default Clustering algorithm. For this sample,
-- we skip specification of any overrides to defaults
--
-- Uncomment the appropriate sections of the code below for
-- changing settings values.
-- 
set echo on
CREATE TABLE em_sh_sample_settings (
   setting_name  VARCHAR2(30),
   setting_value VARCHAR2(4000));
 
BEGIN       
   INSERT INTO em_sh_sample_settings (setting_name, setting_value) VALUES
   (dbms_data_mining.algo_name, dbms_data_mining.algo_expectation_maximization);
   INSERT INTO em_sh_sample_settings (setting_name, setting_value) VALUES 
   (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
   -- Other examples of overrides are:
   -- (dbms_data_mining.emcs_num_components,15);
   -- (dbms_data_mining.clus_num_clusters,5);
   -- (dbms_data_mining.emcs_cluster_comp_enable,
   --  dbms_data_mining.emcs_cluster_comp_disable);
   -- (dbms_data_mining.emcs_attribute_filter,
   --  dbms_data_mining.emcs_attr_filter_disable);
   -- (dbms_data_mining.emcs_linkage_function,
   --  dbms_data_mining.emcs_linkage_average);
   -- (dbms_data_mining.emcs_num_iterations,200);
   -- (dbms_data_mining.emcs_loglike_improvement,1e-10);
END;
/

---------------------
-- CREATE A NEW MODEL
--
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'EM_SH_Clus_sample',
    mining_function     => dbms_data_mining.clustering,
    data_table_name     => 'mining_data_build_parallel_v',
    case_id_column_name => 'cust_id',
    settings_table_name => 'em_sh_sample_settings');
END;
/

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

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='EM_SH_CLUS_SAMPLE'
  ORDER BY view_name;

-- Attribute importance
-- 2D attributes are ranked based on their interactions with other attributes.
-- The ranking is based on the scaled pairwise Kullback-Leibler divergence.
col attribute_name format a25
col attribute_name_1 format a25
col attribute_name_2 format a25
col attribute_importance_value format 999.9999
col dependency format 999.9999
  
SELECT attribute_name, attribute_importance_value, attribute_rank
FROM DM$VIEM_SH_CLUS_sample ORDER BY attribute_rank;

SELECT * FROM (
SELECT attribute_name_1, attribute_name_2, dependency
FROM DM$VBEM_SH_CLUS_sample 
WHERE attribute_name_1 < attribute_name_2 ORDER BY dependency desc)
WHERE ROWNUM < 11;

-- Cluster details are best seen in pieces - based on the kind of
-- associations and groupings that are needed to be observed.
--
-- CLUSTERS
-- For each cluster_id, provides the number of records in the cluster,
-- the parent cluster id, the level in the hierarchy, and dispersion -
-- which is a measure of the quality of the cluster, and computationally,
-- the sum of square errors.
--
SELECT cluster_id clu_id, record_count rec_cnt, parent, tree_level
  FROM DM$VDEM_SH_CLUS_SAMPLE
 ORDER BY cluster_id;

-- TAXONOMY
--
SELECT cluster_id, left_child_id, right_child_id
  FROM DM$VDEM_SH_CLUS_SAMPLE
ORDER BY cluster_id;

-- CENTROIDS FOR LEAF CLUSTERS
-- For cluster_id 17, this output lists all the attributes that
-- constitute the centroid, with the mean (for numericals) or
-- mode (for categoricals), along with the variance from mean
--
column attribute_name format a20
column attribute_subname format a20
column mean format 9999999.999
column variance format 9999999.999
column lower_bin_boundary format 9999999.999
column upper_bin_boundary format 9999999.999  
column attribute_value format a20
column mode_value format a20

SELECT cluster_id, attribute_name, attribute_subname, mean, variance,
    mode_value
FROM DM$VAEM_SH_CLUS_SAMPLE
WHERE cluster_id = 17
ORDER BY attribute_name, attribute_subname;

-- HISTOGRAM FOR ATTRIBUTE OF A LEAF CLUSTER
-- For cluster 17, provide the histogram for the AGE attribute.
--
SELECT cluster_id, attribute_name, attribute_subname,
        bin_id, lower_bin_boundary, upper_bin_boundary, attribute_value, count 
FROM DM$VHEM_SH_CLUS_SAMPLE
WHERE cluster_id = 17 AND attribute_name = 'AGE'
ORDER BY bin_id;

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
column numeric_value format 999999.999
column confidence format 999999.999
column rule_confidence format 999999.999
column support format 9999
column rule_support format 9999
column operator format a2

SELECT distinct cluster_id, rule_support, rule_confidence
FROM DM$VREM_SH_CLUS_SAMPLE ORDER BY cluster_id;

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
SELECT cluster_id, attribute_name, attribute_subname, operator,
        numeric_value, attribute_value, support, confidence 
FROM DM$VREM_SH_CLUS_SAMPLE 
WHERE cluster_id < 3
ORDER BY cluster_id, attribute_name, attribute_subname, operator,
  numeric_value, attribute_value;

-- Global EM model statistics
-- This view shows high-level model statistics, including
-- number of components, number of clusters, and log likelihood value
column numeric_value format 9999999.999
column string_value format a20
select name, numeric_value, string_value from DM$VGEM_SH_CLUS_SAMPLE
ORDER BY name;

-- EM component details
-- Component priors and mapping to leaf clusters view
col prior_probability format 9.999
select component_id, cluster_id, prior_probability
from DM$VOEM_SH_CLUS_SAMPLE
ORDER BY component_id;

-- Means and variances for attributes modeled with Gaussian distributions
column attribute_name format a25
select component_id, attribute_name, mean, variance
from DM$VMEM_SH_CLUS_sample
WHERE component_id = 11  
ORDER BY attribute_name;  

-- Frequences for attributes modeled with multivalued Bernoulli 
-- distributions
column attribute_value format a15 
column frequency format 9999999.999
select component_id, attribute_name, attribute_value, frequency
from DM$VFEM_SH_CLUS_SAMPLE
WHERE component_id=11    
ORDER BY attribute_name, attribute_value;

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
  FROM mining_data_apply_parallel_v
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
          FROM mining_data_apply_parallel_v))
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
    FROM mining_data_apply_parallel_v v
   WHERE cust_id = 100955) T, 
  TABLE(T.pset) S
order by 2 desc;
