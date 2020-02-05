Rem $Header: tk_datamining/tmdm/sql/tkmdemo.sql /main/3 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem kmdemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      kmdemo.sql - k_means demo for DBMS_DATA_MINING package
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for clustering function
Rem      (Kmeans algorithm). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    jiawang     07/22/04 - Add order by to fix sorting dif 
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    dmukhin     09/03/03 - name changes
Rem    cbhagwat    09/05/03 - kmn settings
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    bmilenov    07/01/03 - Fix nval formatting
Rem    ramkrish    06/30/03 - fix rank apply query
Rem    bmilenov    06/28/03 - Add get_model_details_km demo section
Rem    ramkrish    06/26/03 - SET trimspool on
Rem    fcay        06/23/03 - Update copyright notices
Rem    ramkrish    06/22/03 - chg BUILD to CREATE_MODEL
Rem    cbhagwat    06/16/03 - review changes
Rem    cbhagwat    06/10/03 - mining_data changes
Rem    cbhagwat    05/29/03 - dbms_dm_xform => dbms_data_mining_transform
Rem    cbhagwat    05/05/03 - Creation
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000

-- For get_model_details
column mode_val format a20;
column attribute_name format a25;
column label format a25;
column nval format 9999.9999;
column sval format a10; 
column antecedent format a30;
SET line 250;  

BEGIN
  dbms_data_mining.drop_model('KM_Sample');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

---------------
-- CREATE MODEL
---------------

-- Prepare mining_data_build data as appropriate 
--
  execute dm_demo_drop_object('km_sample_norm','table');
  execute dm_demo_drop_object('km_sample_build_prepared','view');
BEGIN
  -- Create a normalization table
  dbms_data_mining_transform.create_norm_lin (
    norm_table_name => 'km_sample_norm');
                          
  -- Normalize appropriate columns   
  dbms_data_mining_transform.insert_norm_lin_zscore (
    norm_table_name => 'km_sample_norm',
    data_table_name => 'mining_data_build',
    exclude_list    => dbms_data_mining_transform.column_list (
                       'WKS_SINCE_LAST_PURCH',
                       'AFFINITY_CARD',
                       'NO_DIFFERENT_KIND_ITEMS',
                       'DISABLE_COOKIES',
                       'PROMO_RESPOND',
                       'MAILING_LIST',
                       'SR_CITIZEN',
                       'BULK_PACK_DISKETTES',
                       'FLAT_PANEL_MONITOR',
                       'HOME_THEATER_PACKAGE',
                       'BOOKKEEPING_APPLICATION',
                       'PRINTER_SUPPLIES',
                       'Y_BOX_GAMES',
                       'OS_DOC_SET_KANJI',
                       'PETS',
                       'id'),
    round_num       => 0
  );
  
  -- Create the transformed view
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'km_sample_norm',
    data_table_name => 'mining_data_build',
    xform_view_name => 'km_sample_build_prepared');
END;
/       

-- KMNS settings
-- Uncomment the appropriate setting for overriding defaults
-- INSERT INTO kmns_settings values 
--(dbms_data_mining.kmns_block_growth,2);
--(dbms_data_mining.kmns_conv_tolerance,0.01);
--(dbms_data_mining.kmns_distance,dbms_data_mining.kmns_euclidean);
--(dbms_data_mining.kmns_iterations,3);
--(dbms_data_mining.kmns_num_bins,10);
--(dbms_data_mining.kmns_min_pct_attr_support,0.1);
--(dbms_data_mining.kmns_split_criterion,dbms_data_mining.kmns_variance);

-- Create KM Model
BEGIN
  dbms_output.put_line('Invoking DBMS_DATA_MINING.CREATE_MODEL - Kmeans');
  dbms_data_mining.create_model(
    model_name => 'KM_Sample',
    mining_function => dbms_data_mining.clustering,
    data_table_name => 'km_sample_build_prepared',
    case_id_column_name => 'id');
  dbms_output.put_line('Completed creation of Kmeans model');
END;
/

set echo on    
-- Display the model signature
--
SELECT *
  FROM TABLE(dbms_data_mining.get_model_signature('KM_Sample'))
ORDER BY attribute_name;

-- Display the model details
--
-- Cluster Description
--
SELECT a.id cluster_id, a.record_count, a.parent, a.tree_level
FROM (SELECT * 
        FROM TABLE(dbms_data_mining.get_model_details_km('KM_SAMPLE'))) a;

-- Taxonomy
--
SELECT a.id cluster_id, ch.id child_id
FROM (SELECT * 
        FROM TABLE(dbms_data_mining.get_model_details_km('KM_SAMPLE'))) a,
     TABLE(a.child) ch;

-- Centroid for two leaf clusters
--
SELECT a.id, c.attribute_name, c.mean, c.mode_value mode_val, c.variance var
FROM (SELECT * 
      FROM TABLE(dbms_data_mining.get_model_details_km('KM_SAMPLE'))) a,
     TABLE(a.centroid) c
WHERE a.id > 17
ORDER BY a.id, c.attribute_name;

-- Histogram for two leaf clusters
--
SELECT a.id, h.attribute_name, h.label, h.count
  FROM (SELECT *
          FROM TABLE(dbms_data_mining.get_model_details_km('KM_SAMPLE'))) a,
       TABLE(a.histogram) h
 WHERE a.id > 17
ORDER BY a.id, h.attribute_name, h.label;

-- Histogram Rules for two leaf clusters 
--
SELECT a.id rule_id, a.rule.rule_support support, 
       a.rule.rule_confidence confidence
  FROM (SELECT *
          FROM TABLE(dbms_data_mining.get_model_details_km('KM_SAMPLE'))) a
 WHERE a.id > 17;

-- Rule details for two leaf clusters 
--
SELECT a.id rule_id, at.attribute_name, at.conditional_operator op, 
       at.ATTRIBUTE_NUM_VALUE nval, at.ATTRIBUTE_STR_VALUE sval, 
       at.ATTRIBUTE_SUPPORT support, at.ATTRIBUTE_CONFIDENCE confidence
  FROM (SELECT *
          FROM TABLE(dbms_data_mining.get_model_details_km('KM_SAMPLE'))) a,
       TABLE(a.rule.antecedent) at
 WHERE a.id > 17 ORDER BY rule_id,at.attribute_name,support,confidence,nval,sval;
set echo off

--------------
-- APPLY MODEL
--------------

  execute dm_demo_drop_object('km_sample_apply_result','table');
  execute dm_demo_drop_object('km_sample_apply_ranked','table');
  execute dm_demo_drop_object('km_sample_apply_prepared','view');      
-- Prepare apply data
BEGIN
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'km_sample_norm',
    data_table_name => 'mining_data_apply',
    xform_view_name => 'km_sample_apply_prepared');
END;
/

-- Apply
BEGIN
  dbms_output.put_line('Apply model on scoring data');
  dbms_data_mining.apply(
    model_name => 'KM_sample',
    data_table_name => 'km_sample_apply_prepared',
    case_id_column_name => 'id',
    result_table_name => 'km_sample_apply_result');
  dbms_output.put_line('Completed apply');
END;
/

-- Display apply result
SELECT *
  FROM (SELECT id,cluster_id,round(probability,4) probability
          FROM km_sample_apply_result
        ORDER BY  id, probability,cluster_id)
 WHERE rownum < 11;
 
-- Rank the apply results
BEGIN
  dbms_output.put_line('Rank Apply results');
  dbms_data_mining.rank_apply (
    apply_result_table_name => 'km_sample_apply_result',
    case_id_column_name => 'id',
    score_column_name => 'CLUSTER_ID',
    score_criterion_column_name => 'PROBABILITY',
    ranked_apply_table_name => 'km_sample_apply_ranked',
    top_n                   => 2);
END;
/

SELECT *
  FROM (SELECT id,cluster_id,round(probability,4) probability,
               round(cost,4) cost, rank
          FROM km_sample_apply_ranked
        ORDER BY id,rank)
 WHERE ROWNUM < 11;
