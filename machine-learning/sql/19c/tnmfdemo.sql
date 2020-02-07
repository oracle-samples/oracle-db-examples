Rem
Rem $Header: tk_datamining/tmdm/sql/tnmfdemo.sql /main/2 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem nmfdemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      nmfdemo.sql - dbms Data Mining
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for feature selection function
Rem      (Non-negative matrix factorization Algorithm). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    cbhagwat    10/17/03 - feature_extraction
Rem    dmukhin     09/03/03 - name changes
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    cbhagwat    07/08/03 - add details
Rem    ramkrish    06/26/03 - SET trimspool on
Rem    fcay        06/23/03 - Update copyright notice
Rem    ramkrish    06/22/03 - chg BUILD to CREATE_MODEL
Rem    cbhagwat    06/16/03 - review changes
Rem    cbhagwat    06/10/03 - mining_data changes
Rem    cbhagwat    05/29/03 - dbms_dm_xform => dbms_data_mining_transform
Rem    cbhagwat    04/18/03 - fix
Rem    cbhagwat    04/17/03 - parameter names: removed p_
Rem    cbhagwat    04/15/03 - Creation
  
SET serveroutput ON
SET trimspool ON
SET pages 10000

BEGIN  
  dbms_data_mining.drop_model('NMF_Sample');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

----------------
-- CREATE MODEL
----------------
-- Prepare mining_data_build data as appropriate 
--
  execute dm_demo_drop_object('nmf_sample_norm','table');
  execute dm_demo_drop_object('nmf_sample_build_prepared','view');
BEGIN
  -- Create a normalization table
  dbms_data_mining_transform.create_norm_lin (
    norm_table_name => 'nmf_sample_norm');
                          
  -- Normalize appropriate columns   
  dbms_data_mining_transform.insert_norm_lin_minmax (
    norm_table_name => 'nmf_sample_norm',
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
    norm_table_name => 'nmf_sample_norm',
    data_table_name => 'mining_data_build',
    xform_view_name => 'nmf_sample_build_prepared');
END;
/       
-- NMFS settings (For info only)
-- insert into nmfs_settings values
--(dbms_data_mining.nmfs_conv_tolerance,0.05);
--(dbms_data_mining.nmfs_num_iterations,50);
--(dbms_data_mining.nmfs_random_seed,-1);
--(dbms_data_mining.nmfs_stop_criteria,dbms_data_mining.nmfs_sc_iter_or_conv);
-- Invoke NMF Build
BEGIN
  dbms_output.put_line(
  'Invoking DBMS_DATA_MINING.CREATE_MODEL- Non-negative Matrix Factorization');
  dbms_data_mining.create_model(
    model_name => 'NMF_Sample',
    mining_function => dbms_data_mining.feature_extraction,
    data_table_name => 'nmf_sample_build_prepared',
    case_id_column_name => 'id');
  dbms_output.put_line('Completed Non-negative Matrix Factorization Build');
END;
/
    
-- display model settings
SELECT *
  FROM TABLE(dbms_data_mining.get_model_settings('NMF_Sample'))
ORDER BY setting_name;

-- display the model signature
SELECT *
  FROM TABLE(dbms_data_mining.get_model_signature('NMF_Sample'))
ORDER BY attribute_name;

-- Get model details
column attribute_name format a30;
column attribute_value format a30;
set pages 15

SELECT t.feature_id,
  a.attribute_name,
  a.attribute_value,
  a.coefficient
  FROM TABLE(dbms_data_mining.get_model_details_nmf('NMF_Sample')) t,
  TABLE(t.attribute_set) a
  ORDER BY 1,2,3,4;

--------
-- APPLY 
--------

-- Prepare apply data
  execute dm_demo_drop_object('nmf_sample_apply_prepared','view');
BEGIN
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'nmf_sample_norm',
    data_table_name => 'mining_data_apply',
    xform_view_name => 'nmf_sample_apply_prepared');
END;
/

-- Apply
  execute dm_demo_drop_object('nmf_sample_apply_result','table');
  execute dm_demo_drop_object('nmf_sample_apply_ranked','table');
BEGIN
  dbms_output.put_line('Apply on apply data');
  dbms_data_mining.apply(
    model_name => 'NMF_sample',
    data_table_name => 'nmf_sample_apply_prepared',
    case_id_column_name => 'id',
    result_table_name => 'nmf_sample_apply_result');
  dbms_output.put_line('Completed apply');
END;
/

-- Display apply result
SELECT *
  FROM (SELECT *
          FROM nmf_sample_apply_result
        ORDER BY id,feature_id)
 WHERE rownum < 11;
 
-- Rank the apply results
BEGIN
  dbms_output.put_line('Rank Apply results');
  dbms_data_mining.rank_apply (
    apply_result_table_name => 'nmf_sample_apply_result',
    case_id_column_name     => 'id',
    score_column_name => 'FEATURE_ID',
    score_criterion_column_name => 'match_quality',
    ranked_apply_table_name => 'nmf_sample_apply_ranked',
    top_n                   => 2);
END;
/

SELECT *
  FROM (SELECT * 
          FROM nmf_sample_apply_ranked
        ORDER BY rank,id,feature_id)
 WHERE ROWNUM < 11;
