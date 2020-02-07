Rem
Rem $Header: tk_datamining/tmdm/sql/taidemo.sql /main/2 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem aidemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      aidemo.sql - Sample program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for attribute importance function (Predictive Variance Algorithm). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    gtang       12/08/03 - remove selecting settings table, because  
Rem                           it is not used anymore
Rem    dmukhin     09/02/03 - name changes
Rem    cbhagwat    08/04/03 - cbhagwat_txn108319
Rem    cbhagwat    08/04/03 - fix comment
Rem    cbhagwat    07/31/03 - Creation
  
SET serveroutput ON
SET trimspool ON
SET pages 10000

BEGIN  
  dbms_data_mining.drop_model('AI_Sample');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
---------------
-- CREATE MODEL
---------------
  -- Prepare mining_data_build data as appropriate
  EXECUTE dm_demo_drop_object('ai_sample_num_boundary','table');
  EXECUTE dm_demo_drop_object('ai_sample_cat_boundary','table'); 
  EXECUTE dm_demo_drop_object('ai_sample_build_prepared','view');
  EXECUTE dm_demo_drop_object('ai_sample_build_cat','view');
 
-- Prepare mining_data_build data as appropriate  
BEGIN
  -- Make a numerical bin boundary table   
  dbms_data_mining_transform.create_bin_num (
    bin_table_name => 'ai_sample_num_boundary');
                         
  -- Create boundaries for age, annual_income, bulk_purch_ave_amt  (10 bins)   
  dbms_data_mining_transform.insert_bin_num_eqwidth (
    bin_table_name    => 'ai_sample_num_boundary',
    data_table_name   => 'mining_data_build',
    bin_num           => 10,
    exclude_list      => dbms_data_mining_transform.column_list (
                       'WKS_SINCE_LAST_PURCH',
                       'AFFINITY_CARD',
                       'average___items_purchased',
                       'NO_DIFFERENT_KIND_ITEMS',
                       'YRS_RESIDENCE',
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
    round_num         => 0
  );    

  -- Create boundaries for AVERAGE___ITEMS_PURCHASED, YRS_RESIDENCE 4 bins
  dbms_data_mining_transform.insert_bin_num_eqwidth (
    bin_table_name    => 'ai_sample_num_boundary',
    data_table_name   => 'mining_data_build',
    bin_num           => 4,
    exclude_list      => dbms_data_mining_transform.column_list (
                       'WKS_SINCE_LAST_PURCH',
                       'AFFINITY_CARD',
                       'AGE',
                       'ANNUAL_INCOME',
                       'BULK_PURCH_AVE_AMT',
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
    round_num         => 0
  );

  -- Bin Workclass (categorical)
  dbms_data_mining_transform.create_bin_cat (
    bin_table_name    => 'ai_sample_cat_boundary');        
  dbms_data_mining_transform.insert_bin_cat_freq (
    bin_table_name    => 'ai_sample_cat_boundary',
    data_table_name   => 'mining_data_build',
    bin_num           => 5,
    exclude_list      => dbms_data_mining_transform.column_list (
                       'education',
                       'MARITAL_STATUS',
                       'OCCUPATION',
                       'HOUSEHOLD_SIZE',
                       'TOP_REASON_FOR_SHOPPING',
                       'GENDER',
                       'SHIPPING_ADDRESS_COUNTRY'),
    default_num       => 0
  );
  -- Make default bin NULL
  EXECUTE IMMEDIATE
    'DELETE FROM ai_sample_cat_boundary WHERE val IS NULL';
 
  -- Create the transformed view
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'ai_sample_cat_boundary',
    data_table_name => 'mining_data_build',
    xform_view_name => 'ai_sample_build_cat');    
  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'ai_sample_num_boundary',
    data_table_name => 'ai_sample_build_cat',
    xform_view_name => 'ai_sample_build_prepared');    
END;
/
     
-- Create Naive Bayes Model
BEGIN
  dbms_output.put_line('Invoking DBMS_DATA_MINING.CREATE_MODEL - Attribute Imp');
  dbms_data_mining.create_model(
    model_name => 'AI_Sample',
    mining_function => dbms_data_mining.attribute_importance,
    data_table_name => 'ai_sample_build_prepared',
    case_id_column_name => 'id',
    target_column_name => 'affinity_card');
  dbms_output.put_line('Completed Attribute Importance Build');
END;
/

-- Display the model details    
SELECT *
  FROM TABLE(dbms_data_mining.get_model_details_ai('AI_Sample')) 
ORDER BY RANK;

