-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 19c
-- 
--   Clustering - O-Cluster Algorithm - dmocdemo.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
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
-- mining_data_build_parallel_v (build data)
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

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with the same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('OC_SH_Clus_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
--
BEGIN EXECUTE IMMEDIATE 'DROP TABLE oc_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- K-Means is the default clustering algorithm. Override the
-- default to set the algorithm to O-Cluster using a settings table.
-- 
-- CREATE AND POPULATE A SETTINGS TABLE
--
set echo off
CREATE TABLE oc_sh_sample_settings (
  setting_name  VARCHAR2(30), 
  setting_value VARCHAR2(4000));
set echo on
BEGIN
  INSERT INTO oc_sh_sample_settings VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_ocluster);
  INSERT INTO oc_sh_sample_settings VALUES
    (dbms_data_mining.clus_num_clusters, 10);
  INSERT INTO oc_sh_sample_settings VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);

  -- Other possible settings are:
  -- (dbms_data_mining.oclt_sensitivity, 0.5);
END;
/

---------------------
-- CREATE A NEW MODEL
--
-- Build a new OC model
-- TO_CHAR function is used to transform columns to 
-- categorical attributes since numeric datatypes 
-- are treated as numeric attributes.
DECLARE
  xformlist dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'AFFINITY_CARD', null, 'TO_CHAR(AFFINITY_CARD)', null);
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'BOOKKEEPING_APPLICATION', null, 'TO_CHAR(BOOKKEEPING_APPLICATION)', null);
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'BULK_PACK_DISKETTES', null, 'TO_CHAR(BULK_PACK_DISKETTES)', null);
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'FLAT_PANEL_MONITOR', null, 'TO_CHAR(FLAT_PANEL_MONITOR)', null);
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'HOME_THEATER_PACKAGE', null, 'TO_CHAR(HOME_THEATER_PACKAGE)', null);
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'OS_DOC_SET_KANJI', null, 'TO_CHAR(OS_DOC_SET_KANJI)', null);
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'PRINTER_SUPPLIES', null, 'TO_CHAR(PRINTER_SUPPLIES)', null);
  dbms_data_mining_transform.SET_TRANSFORM(
    xformlist, 'Y_BOX_GAMES', null, 'TO_CHAR(Y_BOX_GAMES)', null);
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'OC_SH_Clus_sample',
    mining_function     => dbms_data_mining.clustering,
    data_table_name     => 'mining_data_build_parallel_v',
    case_id_column_name => 'cust_id',
    settings_table_name => 'oc_sh_sample_settings',
    xform_list => xformlist);
END;
/ 

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

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='OC_SH_CLUS_SAMPLE'
  ORDER BY view_name;

-- Binning information
column attribute_name format a20
column attribute_value format a20
column lower format 99999.999
column upper format 99999.999
  
select attribute_name, bin_id, lower_bin_boundary lower,
  upper_bin_boundary upper, attribute_value
from DM$VBOC_SH_CLUS_sample WHERE attribute_name IN ('AGE', 'CUST_GENDER');

-- Cluster details are best seen in pieces - based on the kind of
-- associations and groupings that are needed to be observed.
--

-- CLUSTERS
-- For each cluster_id, provides the number of records in the cluster,
-- the parent cluster id, and the level in the hierarchy.
-- NOTE: Unlike K-means, O-Cluster does not return a value for the
--       dispersion associated with a cluster.
--
column pname format a20
SELECT cluster_id clu_id, record_count rec_cnt, parent, tree_level
  FROM DM$VDOC_SH_CLUS_SAMPLE
 ORDER BY cluster_id;

-- TAXONOMY
-- 
SELECT cluster_id, left_child_id, right_child_id
  FROM DM$VDOC_SH_CLUS_SAMPLE
ORDER BY cluster_id;

-- SPLIT PREDICATES
-- For each cluster, the split predicate indicates the attribute
-- and the condition used to assign records to the cluster's children
-- during model build. It provides an important piece of information
-- on how the population within a cluster can be divided up into
-- two smaller clusters.
--
column attribute_name format a20
column attribute_subname format a20
column operator format a2
column val format a20
SELECT cluster_id, attribute_name, attribute_subname,
       operator, splits.val
FROM DM$VDOC_SH_CLUS_SAMPLE a,
  XMLTABLE( '/Element' passing a.value 
    columns 
    val varchar2(20) path '.') splits
where left_child_id is not NULL AND cluster_id < 5 
ORDER BY cluster_id, val;  

-- CENTROIDS FOR LEAF CLUSTERS
-- For cluster_id 1, this output lists all the attributes that
-- constitute the centroid, with the mean (for numericals) or
-- mode (for categoricals). Unlike K-Means, O-Cluster does not return 
-- the variance for numeric attributes.
--
column mean format 9999999.999
column variance format 9999999.999
column attribute_value format a20
column mode_value format a20

SELECT cluster_id, attribute_name, attribute_subname, mean, variance,
    mode_value
FROM DM$VAOC_SH_CLUS_SAMPLE
WHERE cluster_id = 1
ORDER BY attribute_name, attribute_subname;

-- HISTOGRAM FOR ATTRIBUTE OF A LEAF CLUSTER
-- For cluster 1, provide the histogram for the AGE attribute.
-- Histogram count is represented in frequency, rather than actual count.
column count format 9999.99
column bin_id format 9999999
column label format a20;

SELECT cluster_id, attribute_name, attribute_subname,
        bin_id, label, count
FROM DM$VHOC_SH_CLUS_SAMPLE
WHERE cluster_id = 1 AND attribute_name = 'AGE'
ORDER BY bin_id;

-- RULES FOR LEAF CLUSTERS
-- See dmkmdemo.sql for explanation on output columns.
column numeric_value format 999999.999
column confidence format 999999.999
column rule_confidence format 999999.999
column support format 9999
column rule_support format 9999

SELECT distinct cluster_id, rule_support, rule_confidence
FROM DM$VROC_SH_CLUS_SAMPLE ORDER BY cluster_id;

-- RULE DETAILS FOR LEAF CLUSTERS
-- See dmkmdemo.sql for explanation on output columns.
SELECT cluster_id, attribute_name, attribute_subname, operator,
        numeric_value, attribute_value, support, confidence 
FROM DM$VROC_SH_CLUS_SAMPLE 
WHERE cluster_id < 3
ORDER BY cluster_id, attribute_name, attribute_subname, operator,
  numeric_value, attribute_value;

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
