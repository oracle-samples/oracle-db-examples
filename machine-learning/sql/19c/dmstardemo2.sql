Rem
Rem $Header: tk_datamining/tmdm/sql/dmstardemo2.sql /main/1 2016/03/05 00:05:15 jiangzho Exp $
Rem
Rem dmstardemo2.sql
Rem
Rem Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      dmstardemo2.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jiangzho    02/21/16 - validate existing models
Rem    jiangzho    02/21/16 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100


-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'DM_STAR_CLUSTER'
ORDER BY setting_name;

--------------------------
-- DISPLAY MODEL SIGNATURE
--
column attribute_name format a30
column attribute_type format a20
column data_type format a20
SELECT attribute_name, attribute_type, data_type
  FROM user_mining_model_attributes
 WHERE model_name = 'DM_STAR_CLUSTER'
ORDER BY attribute_name;


------------------------
-- DISPLAY MODEL DETAILS
--

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='DM_STAR_CLUSTER'
  ORDER BY view_name;

-- Cluster details are best seen in pieces - based on the kind of
-- associations and groupings that are needed to be observed.
--
-- CLUSTERS
-- For each cluster_id, provides the number of records in the cluster,
-- the parent cluster id, the level in the hierarchy, and dispersion -
-- which is a measure of the quality of the cluster, and computationally,
-- the sum of square errors.
--
SELECT cluster_id clu_id, record_count rec_cnt, parent, tree_level, 
       TO_NUMBER(dispersion) dispersion
  FROM DM$VDDM_STAR_CLUSTER
 ORDER BY cluster_id;

-- TAXONOMY
--
SELECT cluster_id, left_child_id, right_child_id
  FROM DM$VDDM_STAR_CLUSTER
ORDER BY cluster_id;

-- CENTROIDS FOR LEAF CLUSTERS
-- For cluster_id 16, this output lists all the attributes that
-- constitute the centroid, with the mean (for numericals) or
-- mode (for categoricals)
-- Note that per-subcategory sales for each customer are being
-- considered when creating clusters.
--
column aname format a60
column mode_val format a40
column mean_val format 9999999
SELECT NVL2(C.attribute_subname, 
            C.attribute_name || '.' || C.attribute_subname, 
            C.attribute_name) aname,
       C.mean mean_val,
       C.mode_value mode_val
  FROM DM$VADM_STAR_CLUSTER c
WHERE cluster_id = 16
ORDER BY aname;

-------------------------------------------------
-- SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
--
------------------
-- BUSINESS CASE 1
-- List the clusters into which the customers in this
-- given dataset have been grouped.
--
SELECT CLUSTER_ID(DM_STAR_CLUSTER USING *) AS clus, COUNT(*) AS cnt 
  FROM cust_with_sales
GROUP BY CLUSTER_ID(DM_STAR_CLUSTER USING *)
ORDER BY cnt DESC;
--
------------------
-- BUSINESS CASE 2
-- List the five most relevant attributes for likely cluster assignments
-- for customer id 100955 (> 20% likelihood of assignment).
--
column prob format 9.9999
set line 150
set long 10000
SELECT S.cluster_id, probability prob, 
       CLUSTER_DETAILS(DM_STAR_CLUSTER, S.cluster_id, 5 using T.*) det
FROM 
  (SELECT v.*, CLUSTER_SET(DM_STAR_CLUSTER, NULL, 0.2 USING *) pset
    FROM cust_with_sales v
   WHERE cust_id = 100949) T, 
  TABLE(T.pset) S
order by 2 desc;
