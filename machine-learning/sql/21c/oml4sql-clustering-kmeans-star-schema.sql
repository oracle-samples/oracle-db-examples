-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 21c
-- 
--   Clustering - K-Means Algorithm - dmstardemo.sql
--   
--   Copyright (c) 2021 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------
SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100


-------------------
-- STAR SCHEMA
-- Bring together the data in the sh star schema.
-- For mining, include the customer demographics, but also include the
-- per-subcategory purchase amounts that were made for each customer.
-- Include also the dates between which the purchases were made.  
-- This will enhance the clustering model to account for customer
-- behavior as well as demographics.
create or replace view cust_with_sales as
select c.*, v2.sales_from, v2.sales_to, v2.per_subcat_sales from
sh.customers c,
(select v.cust_id, min(v.sales_from) sales_from, max(v.sales_to) sales_to,
        cast(collect(dm_nested_numerical(v.prod_subcategory, v.sum_amount_sold)) 
             as dm_nested_numericals) per_subcat_sales
 from 
 (select s.cust_id, p.prod_subcategory, sum(s.amount_sold) sum_amount_sold,
  min(s.time_id) sales_from, max(s.time_id) sales_to
  from sh.sales s, sh.products p
  where s.prod_id = p.prod_id
  group by s.cust_id, p.prod_subcategory) v
 group by v.cust_id) v2
where c.cust_id = v2.cust_id;

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dm_star_set';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
set echo off
create table dm_star_set (setting_name varchar2(30), setting_value varchar2(4000));
set echo on
BEGIN       
   INSERT INTO dm_star_set (setting_name, setting_value) VALUES 
   (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
   INSERT INTO dm_star_set (setting_name, setting_value) VALUES 
   (dbms_data_mining.kmns_details, dbms_data_mining.kmns_details_all);
END;
/
commit;

---------------------
-- CREATE A NEW MODEL
--
-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('DM_STAR_CLUSTER');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
declare
  xform_list dbms_data_mining_transform.TRANSFORM_LIST;
begin
  -- Transform the purchase dates to a numeric period
  dbms_data_mining_transform.set_transform(xform_list,
    'SALES_PERIOD', NULL, 'SALES_TO - SALES_FROM', NULL);

  -- Transform the country to a categorical attribute since
  -- numeric datatypes are treated as numeric attributes.
  dbms_data_mining_transform.set_transform(xform_list,
    'COUNTRY_ID', NULL, 'TO_CHAR(COUNTRY_ID)', NULL);

  -- Eliminate columns known to be uninteresting,
  -- which will speed up the process.
  -- Alternatively, you can do this when creating the view.
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_EFF_TO', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_EFF_FROM', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_CITY_ID', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_STATE_PROVINCE_ID', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_STREET_ADDRESS', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_FIRST_NAME', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_LAST_NAME', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_MAIN_PHONE_NUMBER', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_EMAIL', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_TOTAL_ID', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_SRC_ID', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'SALES_TO', NULL, NULL, NULL);
  dbms_data_mining_transform.set_transform(xform_list,
    'SALES_FROM', NULL, NULL, NULL);

  -- perform the build
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'DM_STAR_CLUSTER',
    mining_function     => dbms_data_mining.clustering,
    data_table_name     => 'cust_with_sales',
    case_id_column_name => 'cust_id',
    settings_table_name => 'dm_star_set',
    xform_list          => xform_list);
end;
/

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
