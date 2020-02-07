Rem
Rem $Header: tk_datamining/tmdm/sql/tsvmrdem.sql /main/2 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem svmrdemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      svmrdemo.sql - dbms Data Mining
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for regression function (Support Vector Machines Algorithm). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    bmilenov    05/18/04 - change zscore normalization to minmax
Rem    bmilenov    03/01/04 - Change output formatting for rmse and mae
Rem    cbhagwat    02/25/04 - Format changes
Rem    pstengar    10/13/03 - removed get_model_details, not valid for gaussian kernel
Rem    cbhagwat    09/22/03 - svms_Epsilon change
Rem    ramkrish    09/08/03 - add get_model_details_svm
Rem    dmukhin     09/03/03 - name changes
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    ramkrish    06/26/03 - SET trimspool on
Rem    fcay        06/23/03 - Update copyright notices
Rem    ramkrish    06/22/03 - chg BUILD to CREATE_MODEL
Rem    cbhagwat    06/16/03 - review changes
Rem    cbhagwat    06/10/03 - mining_data changes
Rem    cbhagwat    06/04/03 - Rescale apply output to original scale
Rem    cbhagwat    05/29/03 - dbms_dm_xform => dbms_data_mining_transform
Rem    cbhagwat    04/29/03 - cbhagwat_txn107146
Rem    pstengar    04/18/03 - pstengar_txn106872
Rem    cbhagwat    04/18/03 - approx =>regression
Rem    cbhagwat    04/17/03 - parameter names: removed p_
Rem    cbhagwat    03/11/03 - cbhagwat_txn106417
  
SET serveroutput ON
SET trimspool ON
SET pages 10000

BEGIN  
  dbms_data_mining.drop_model('SVM_Regression_Sample');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
  
-- Create settings table
  execute dm_demo_drop_object('svmr_sample_settings','table');
CREATE TABLE svmr_sample_settings
  (setting_name  VARCHAR2(30),
   setting_value VARCHAR2 (30));

-- Populate settings table
BEGIN
  INSERT INTO svmr_sample_settings VALUES
    (dbms_data_mining.svms_kernel_function,
     dbms_data_mining.svms_gaussian);
  -- Uncomment the appropriate line for additional setting overrides
  --(dbms_data_mining.svms_conv_tolerance,0.01);
  --(dbms_data_mining.svms_kernel_cache_size,50000000);
  --(dbms_data_mining.svms_kernel_function,dbms_data_mining.svms_linear);
  COMMIT;
  dbms_output.put_line('Populated settings');
END;
/

---------------
-- CREATE MODEL
---------------
  execute dm_demo_drop_object('svmr_sample_norm','table');
  execute dm_demo_drop_object('svmr_build_prepared','view');
-- Prepare mining_data_build data as appropriate 
--
DECLARE
BEGIN
  -- Create a normalization table
  dbms_data_mining_transform.create_norm_lin (
    norm_table_name => 'svmr_sample_norm');
                       
  -- Normalize appropriate columns   
  dbms_data_mining_transform.insert_norm_lin_minmax (
    norm_table_name => 'svmr_sample_norm',
    data_table_name => 'mining_data_build',
    exclude_list    => dbms_data_mining_transform.column_list (
                       'WKS_SINCE_LAST_PURCH','AFFINITY_CARD',
                       'NO_DIFFERENT_KIND_ITEMS',
                       'DISABLE_COOKIES',
                       'PROMO_RESPOND',
                       'MAILING_LIST',
                       'SR_CITIZEN',
                       'BULK_PACK_DISKETTES',
                       'FLAT_PANEL_MONITOR',
                       'HOME_THEATER_PACKAGE',
                       'BABY',
                       'PRINTER_SUPPLIES',
                       'Y_BOX_GAMES',
                       'OS_DOC_SET_KANJI',
                       'PETS',
                       'id'),
    round_num       => 0
  ); 
  
  -- Create the transformed view
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'svmr_sample_norm',
    data_table_name => 'mining_data_build',
    xform_view_name => 'svmr_build_prepared');
END;
/
     
-- Invoke SVM Regression Build
BEGIN
  dbms_output.put_line(
   'Invoking DBMS_DATA_MINING.CREATE_MODEL - SVM Regression');
  dbms_data_mining.create_model (
    model_name => 'SVM_Regression_Sample',
    mining_function => dbms_data_mining.regression,
    data_table_name => 'svmr_build_prepared',
    case_id_column_name => 'id',
    target_column_name => 'annual_income',
    settings_table_name => 'svmr_sample_settings');
  dbms_output.put_line('Completed SVM Regression Build');
END;
/
        
-- display the model signature
SELECT *
  FROM TABLE(dbms_data_mining.get_model_signature('SVM_Regression_Sample'))
ORDER BY attribute_name;

-- display the model settings
SELECT *
 FROM  TABLE(dbms_data_mining.get_model_settings('SVM_Regression_Sample'))
ORDER BY setting_name;

-------------
-- TEST MODEL 
--------------
  execute dm_demo_drop_object('svmr_sample_test_apply','table');
  execute dm_demo_drop_object('svmr_sample_test_targets','view');
  execute dm_demo_drop_object('svmr_sample_test_prepared','view');
  execute dm_demo_drop_object('svmr_sample_test_rescaled','view');
-- prepare test data
BEGIN
  -- Create the transformed view
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'svmr_sample_norm',
    data_table_name => 'mining_data_test',
    xform_view_name => 'svmr_sample_test_prepared');
END;
/
-- Apply on test data
BEGIN
  dbms_output.put_line('Apply on test data');
  dbms_data_mining.apply(
    model_name => 'SVM_Regression_sample',
    data_table_name => 'svmr_sample_test_prepared',
    case_id_column_name => 'id',
    result_table_name => 'svmr_sample_test_apply');
  dbms_output.put_line('Completed apply on test data');
END;
/
-- Rescale the apply result prediction
-- using the normalization table
CREATE VIEW svmr_sample_test_rescaled AS
SELECT apply.id, (norm.scale * apply.prediction) + norm.shift prediction
  FROM  svmr_sample_test_apply apply,
       svmr_sample_norm norm
 WHERE norm.col = 'ANNUAL_INCOME' -- Name of the target
/
  
-- Create Test targets view ( Original scale - not normalized)
CREATE VIEW svmr_sample_test_targets AS
SELECT id, annual_income
  FROM mining_data_test
/  

column rmse format  9.99EEEE
column mae format  9.99EEEE
-- Compute Root Mean Square Error
SELECT Sqrt(AVG((a.prediction - b.annual_income) *
                (a.prediction - b.annual_income))) rmse
  FROM svmr_sample_test_rescaled a,
       svmr_sample_test_targets b
 WHERE a.id = b.id;

-- Compute Mean Absolute Error
SELECT AVG(Abs(a.prediction - b.annual_income)) mae
  FROM svmr_sample_test_rescaled a,
       svmr_sample_test_targets b
  WHERE a.id = b.id;

--------------
-- APPLY MODEL
--------------
  execute dm_demo_drop_object('svmr_sample_apply_result','table');
  execute dm_demo_drop_object('svmr_sample_rescaled_apply','table');
  execute dm_demo_drop_object('svmr_apply_prepared','view');
-- prepare apply data
BEGIN
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'svmr_sample_norm',
    data_table_name => 'mining_data_apply',
    xform_view_name => 'svmr_apply_prepared');
END;
/
      
-- Apply
BEGIN
  dbms_output.put_line('Apply on apply data');
  dbms_data_mining.apply(
    model_name => 'SVM_Regression_Sample',
    data_table_name => 'svmr_apply_prepared',
    case_id_column_name => 'id',
    result_table_name => 'svmr_sample_apply_result',
    data_schema_name => null);
  dbms_output.put_line('Completed apply');
END;
/

-- Rescale the apply result prediction
-- using the normalization table
CREATE TABLE svmr_sample_rescaled_apply AS
SELECT apply.id, (norm.scale * apply.prediction) + norm.shift prediction
  FROM  svmr_sample_apply_result apply,
       svmr_sample_norm norm
 WHERE norm.col = 'ANNUAL_INCOME' -- Name of the target
/

-- Display apply result
column prediction format 9999999.99  
SELECT *
  FROM (SELECT *
          FROM svmr_sample_rescaled_apply
        ORDER BY id)
 WHERE rownum  <= 10;
