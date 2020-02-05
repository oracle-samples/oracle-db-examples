Rem $Header: tocdemo.sql 07-jul-2004.12:31:57 amozes Exp $
Rem
Rem ocdemo.sql
Rem
Rem Copyright (c) 2004, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      ocdemo.sql - o-cluster demo for DBMS_DATA_MINING package
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for clustering function using o-cluster algorithm
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    amozes      07/07/04 - add missing order by clauses
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    gtang       06/15/04 - add apply
Rem    gtang       05/20/04 - add get_model_details_oc
Rem    gtang       05/06/04 - gtang_txn110497
Rem    gtang       04/27/04 - Creation
Rem

SET serveroutput ON
SET trimspool ON  
SET pages 10000

-- For signature
column attribute_type format a20
  
-- For get_model_details
column mode_val format a20;
column attribute_name format a25;
column label format a25;
column nval format 9999.9999;
column sval format a10; 
column antecedent format a30;
SET line 250;  

-- This procedure is used below - 
-- to ensure successful re-execution of the demo program
CREATE OR REPLACE
PROCEDURE dm_demo_drop_object (object_name VARCHAR2, object_type VARCHAR2) IS
  find_stmt VARCHAR2(150) := 'select 1 from dual where exists'||
                             '(select object_name from user_objects '||
                             'where object_name=UPPER(''';
  ending    VARCHAR2(10) := '''))';
  drop_stmt VARCHAR2(100):= 'DROP ' || object_type || ' ' || object_name;
  obj_exist PLS_INTEGER;
BEGIN
  EXECUTE IMMEDIATE find_stmt||object_name||ending into obj_exist;
  IF obj_exist = 1 THEN
    EXECUTE IMMEDIATE drop_stmt;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/
    
BEGIN
  dbms_data_mining.drop_model('OC_SAMPLE');
  dm_demo_drop_object('OC_SAMPLE_SETTINGS', 'TABLE');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

---------------
-- CREATE MODEL
---------------

-- Create settings table, required by O-Cluster model build
CREATE TABLE OC_SAMPLE_SETTINGS (setting_name VARCHAR2(30), 
                                 setting_value VARCHAR2(30));

BEGIN
  -- Populate settings table
  INSERT INTO OC_SAMPLE_SETTINGS 
       VALUES (dbms_data_mining.algo_name, dbms_data_mining.algo_ocluster);
  INSERT INTO OC_SAMPLE_SETTINGS 
       VALUES (dbms_data_mining.clus_num_clusters, 10);
END;
/
COMMIT;

-- Prepare build data
DECLARE
  bld_data_table VARCHAR2(30) := 'MINING_DATA_BUILD';  
  num_bin_tab    VARCHAR2(30) := 'oc_sample_num_bb';
  excl_list  dbms_data_mining_transform.COLUMN_LIST := 
                  dbms_data_mining_transform.column_list('ID'); 
  bld_xform_v    VARCHAR2(30) := 'oc_sample_bld_xfv_num';
  modl_name      VARCHAR2(30) := 'oc_sample';
BEGIN
  -- Drop existing tables
  dm_demo_drop_object(num_bin_tab, 'TABLE');
  dm_demo_drop_object(bld_xform_v, 'VIEW');
  
  -- bin numerical data as required for O-Cluster model building 
  dbms_data_mining_transform.create_bin_num(num_bin_tab);
  dbms_data_mining_transform.insert_autobin_num_eqwidth(
                                        bin_table_name  => num_bin_tab,
                                        data_table_name => bld_data_table,
                                        exclude_list    => excl_list);
  dbms_data_mining_transform.xform_bin_num(bin_table_name=>num_bin_tab,
                                           data_table_name=>bld_data_table,
                                           xform_view_name=>bld_xform_v,
                                           literal_flag=>TRUE);

  dbms_output.put_line('Invoking DBMS_DATA_MINING.CREATE_MODEL - o-cluster');
  dbms_data_mining.create_model(
                            model_name => modl_name,
                            mining_function => dbms_data_mining.clustering,
                            data_table_name=>bld_xform_v,
                            case_id_column_name => 'ID',
                            settings_table_name => 'OC_SAMPLE_SETTINGS');
  dbms_output.put_line('O-Cluster model "'||modl_name||
                       '" has been built successfully!');
END;
/

--set echo on    
-- Display the model signature
--
SELECT attribute_name, attribute_type
  FROM TABLE(dbms_data_mining.get_model_signature('OC_SAMPLE'))
ORDER BY attribute_type, attribute_name;

---------------------
-- Show model details
---------------------

-- Cluster summary
--
SELECT id cluster_id, record_count, parent, tree_level
  FROM TABLE(dbms_data_mining.get_model_details_oc('OC_SAMPLE'))
ORDER BY id;

-- Taxonomy
--
WITH 
  q1 AS (SELECT id FROM 
    TABLE(dbms_data_mining.get_model_details_oc('OC_SAMPLE'))),
  q2 AS (SELECT c.id, ch.id child_id FROM 
    TABLE(dbms_data_mining.get_model_details_oc('OC_SAMPLE')) c,
    TABLE(c.child) ch)
SELECT a.id, b.child_id FROM 
  q1 a left outer join q2 b ON a.id=b.id ORDER BY id, child_id;

-- Centroid for two leaf clusters
--
SELECT * FROM 
(SELECT a.id, c.attribute_name, c.mean, c.mode_value mode_val
  FROM 
    TABLE(dbms_data_mining.get_model_details_oc('OC_SAMPLE')) a,
    TABLE(a.centroid) c
  WHERE a.id > 17 ORDER BY a.id, c.attribute_name)
  WHERE ROWNUM < 21;

-- Histogram for two leaf clusters
--
col count for 9999.99
col bin_id for 9999999
col id for 99999999
SELECT * FROM 
  (SELECT a.id, h.bin_id, h.attribute_name, h.label, h.count
    FROM
      TABLE(dbms_data_mining.get_model_details_oc('OC_SAMPLE')) a,
      TABLE(a.histogram) h
    WHERE a.id > 17 ORDER BY a.id, h.attribute_name, h.bin_id)
  WHERE ROWNUM < 21;

-- Cluster Rule summary
--
col confidence for 999999.99
col nval FOR 99999
  
SELECT a.id rule_id, a.rule.rule_support support, 
       a.rule.rule_confidence confidence
  FROM TABLE(dbms_data_mining.get_model_details_oc('OC_SAMPLE')) a
  WHERE a.id > 17
ORDER BY rule_id;

-- Cluster Rule details
--
SELECT * FROM 
  (SELECT a.id rule_id, an.attribute_name, an.conditional_operator op, 
       an.ATTRIBUTE_NUM_VALUE nval, an.ATTRIBUTE_STR_VALUE sval, 
       an.ATTRIBUTE_SUPPORT support, an.ATTRIBUTE_CONFIDENCE confidence
    FROM
      TABLE(dbms_data_mining.get_model_details_oc('OC_SAMPLE')) a,
      TABLE(a.rule.antecedent) an
    WHERE a.id > 17
    ORDER BY rule_id, attribute_name, op, nval, sval) 
  WHERE ROWNUM < 21;

--set echo off  
  
--------------
-- APPLY MODEL
--------------

-- Clean up
BEGIN
  dm_demo_drop_object('oc_sample_apl_result', 'table');
  dm_demo_drop_object('oc_sample_apl_rank', 'table');
  dm_demo_drop_object('oc_sample_apl_xfv_num', 'view');   
END;
/

BEGIN
  -- Prepare apply data
  dbms_data_mining_transform.xform_bin_num(bin_table_name =>'oc_sample_num_bb',
                                           data_table_name=>'MINING_DATA_APPLY',
                                           xform_view_name=>'oc_sample_apl_xfv_num',
                                           literal_flag=>TRUE);

  -- Apply
  dbms_output.put_line('Apply model on scoring data');
  dbms_data_mining.apply(
    model_name => 'oc_sample',
    data_table_name => 'oc_sample_apl_xfv_num',
    case_id_column_name => 'ID',
    result_table_name => 'oc_sample_apl_result');
  dbms_output.put_line('Completed apply');
END;
/

-- Display apply result
column probability format 99.999
  
SELECT * FROM 
  (SELECT id, cluster_id, probability
    FROM oc_sample_apl_result ORDER BY id, cluster_id, probability)
  WHERE rownum < 11;
 
-- Rank the apply results
BEGIN
  dbms_output.put_line('Rank Apply results');
  dbms_data_mining.rank_apply (
    apply_result_table_name     => 'oc_sample_apl_result',
    case_id_column_name         => 'ID',
    score_column_name           => 'CLUSTER_ID',
    score_criterion_column_name => 'PROBABILITY',
    ranked_apply_table_name     => 'oc_sample_apl_rank',
    top_n                       => 2);
END;
/

SELECT *
  FROM (SELECT id, cluster_id, round(probability, 4) probability,
               round(cost, 4) cost, rank
          FROM oc_sample_apl_rank ORDER BY id, cluster_id, rank)
  WHERE ROWNUM < 11;
