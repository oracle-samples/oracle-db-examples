Rem
Rem $Header: tk_datamining/tmdm/sql/tsvmcdem.sql /main/3 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem svmcdemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      svmcample.sql - Sample program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for classification function (SVM Algorithm - Classification). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    cbhagwat    05/17/05 - fix reproducibility issue 
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    bmilenov    05/18/04 - change zscore normalization to minmax
Rem    cbhagwat    02/25/04 - Format changes
Rem    cbhagwat    09/22/03 - svms_Epsilon change
Rem    ramkrish    09/08/03 - add get_model_details_svm
Rem    dmukhin     09/03/03 - name changes
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    ramkrish    06/26/03 - SET trimspool on
Rem    fcay        06/23/03 - Update copyright notice
Rem    ramkrish    06/22/03 - chg BUILD to CREATE_MODEL
Rem    cbhagwat    06/16/03 - review changes
Rem    cbhagwat    06/10/03 - mining_data changes
Rem    cbhagwat    05/29/03 - dbms_dm_xform => dbms_data_mining_transform
Rem    cbhagwat    05/20/03 - remove precision_recall
Rem    cbhagwat    04/18/03 - fix
Rem    cbhagwat    04/17/03 - parameter names: removed p_
Rem    cbhagwat    04/11/03 - new compute APIs
Rem    cbhagwat    02/25/03 - Creation
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000

BEGIN
  -- Drop the model
  dbms_data_mining.drop_model('SVM_Clas_sample');
EXCEPTION WHEN others THEN NULL;
END;
/

-- Create cost table
  execute dm_demo_drop_object('svmc_cost','table');
CREATE TABLE svmc_cost (
  actual_target_value    NUMBER,
  predicted_target_value NUMBER,
  cost                   NUMBER);

-- Create settings table
  execute dm_demo_drop_object('svmc_sample_settings','table');
CREATE TABLE svmc_sample_settings (
  setting_name VARCHAR2(30),
  setting_value VARCHAR2 (30));
 
BEGIN
  -- Populate cost table
  INSERT INTO svmc_cost VALUES (0,0,0);
  INSERT INTO svmc_cost VALUES (0,1,0.65);
  INSERT INTO svmc_cost VALUES (1,0,0.45);
  INSERT INTO svmc_cost VALUES (1,1,0);
  
  -- Populate settings table
  INSERT INTO svmc_sample_settings VALUES
    (dbms_data_mining.algo_name,
     dbms_data_mining.algo_support_vector_machines);
  --(dbms_data_mining.svms_conv_tolerance,0.01);
  --(dbms_data_mining.svms_kernel_cache_size,50000000);
  --(dbms_data_mining.svms_kernel_function,dbms_data_mining.svms_linear);
  COMMIT;
  dbms_output.put_line('Populated settings and cost');
END;
/

---------------
-- CREATE MODEL
---------------

  execute dm_demo_drop_object('svmc_sample_norm','table');
  execute dm_demo_drop_object('svmc_sample_build_prepared','view');
-- Prepare mining_data_build data as appropriate  
BEGIN
  -- Make a numerical bin boundary table   
  dbms_data_mining_transform.create_norm_lin (
    norm_table_name => 'svmc_sample_norm');
                         
  -- Normalize data   
  dbms_data_mining_transform.insert_norm_lin_minmax (
    norm_table_name => 'svmc_sample_norm',
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
    norm_table_name => 'svmc_sample_norm',
    data_table_name => 'mining_data_build',       
    xform_view_name => 'svmc_sample_build_prepared');    
END;
/

-- Create SVM model
BEGIN
  dbms_output.put_line(
   'Invoking DBMS_DATA_MINING.CREATE_MODEL - SVM Classification');
  dbms_data_mining.create_model(
    model_name => 'SVM_Clas_sample',
    mining_function => dbms_data_mining.classification,
    data_table_name => 'svmc_sample_build_prepared',
    case_id_column_name => 'id',
    target_column_name => 'affinity_card',
    settings_table_name => 'svmc_sample_settings');
  dbms_output.put_line('Completed SVM - Classification Build');
END;
/ 
 
-- Display the model settings   
SELECT *
  FROM TABLE(dbms_data_mining.get_model_settings('SVM_Clas_sample'));

-- Display the model signature
SELECT *
  FROM TABLE(dbms_data_mining.get_model_signature('SVM_Clas_sample'))
ORDER BY attribute_name;

-- Display model details
SET line 120
column attribute_value format a30
column coefficient format 9.99
SELECT * FROM (
  WITH model_details AS
    (SELECT * FROM
     TABLE(dbms_data_mining.get_model_details_svm('SVM_Clas_sample')))
  SELECT d.class,a.attribute_name,
    a.attribute_value,a.coefficient
    FROM model_details d,
    TABLE(d.attribute_set) a
    ORDER BY class,Abs(coefficient) DESC
) WHERE ROWNUM < 6;	       
-------
-- TEST
-------
  execute dm_demo_drop_object('svmc_sample_test_apply','table');
  execute dm_demo_drop_object('svmc_sample_confusion_matrix','table');
  execute dm_demo_drop_object('svmc_sample_lift','table');
  execute dm_demo_drop_object('svmc_sample_roc','table');
  execute dm_demo_drop_object('svmc_sample_test_targets','view');
  execute dm_demo_drop_object('svmc_sample_test_prepared','view');
-- Prepare test data
BEGIN
   -- Create the transformed view
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'svmc_sample_norm',
    data_table_name => 'mining_data_test',
    xform_view_name => 'svmc_sample_test_prepared');
END;
/

-- Apply on test data
BEGIN
  dbms_output.put_line('Apply on test data');
  dbms_data_mining.apply(
    model_name => 'SVM_Clas_sample',
    data_table_name => 'svmc_sample_test_prepared',
    case_id_column_name => 'id',
    result_table_name => 'svmc_sample_test_apply');
  dbms_output.put_line('Completed apply on test data');
END;
/
  
-- Create Test targets view
CREATE VIEW svmc_sample_test_targets AS
SELECT id, affinity_card
  FROM svmc_sample_test_prepared;

-- Test the model
DECLARE
  v_accuracy NUMBER;
  v_area_under_curve NUMBER;
 BEGIN
   dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX');
   dbms_data_mining.compute_confusion_matrix (
     accuracy => v_accuracy,
     apply_result_table_name => 'svmc_sample_test_apply',
     target_table_name => 'svmc_sample_test_targets',
     case_id_column_name => 'id',
     target_column_name => 'affinity_card',
     confusion_matrix_table_name => 'svmc_sample_confusion_matrix',
     score_column_name      => 'PREDICTION',
     score_criterion_column_name        => 'PROBABILITY',
     cost_matrix_table_name => 'svmc_cost');
   dbms_output.put_line(
    'Confusion_matrix created in svmc_sample_confusion_matrix');
   dbms_output.put_line('Accuracy: ' || To_char(v_accuracy,'9.99'));
   
   dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_LIFT');     
   dbms_data_mining.compute_lift (
     apply_result_table_name => 'svmc_sample_test_apply',
     target_table_name => 'svmc_sample_test_targets',
     case_id_column_name => 'id',
     target_column_name => 'affinity_card',
     lift_table_name => 'svmc_sample_lift',
     positive_target_value => '1',
     num_quantiles => '10',
     cost_matrix_table_name => 'svmc_cost');
   dbms_output.put_line('Lift results created in svmc_sample_lift');

   -- Compute ROC
   dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_ROC');
   dbms_data_mining.compute_roc (
     roc_area_under_curve => v_area_under_curve,
     apply_result_table_name => 'svmc_sample_test_apply',
     target_table_name => 'svmc_sample_test_targets',
     case_id_column_name => 'id',
     target_column_name => 'affinity_card',
     roc_table_name => 'svmc_sample_roc',
     positive_target_value => '1',
     score_column_name => 'PREDICTION',
     score_criterion_column_name => 'PROBABILITY');
   dbms_output.put_line('ROC created in  svmc_sample_roc');
   dbms_output.put_line('Area under the curve: ' ||
			  To_char(v_area_under_curve,'9.99'));
END;
/

-- Display confusion matrix table.
SELECT *
  FROM svmc_sample_confusion_matrix
ORDER BY actual_target_value,predicted_target_value;

-- Display few quantiles in lift result table
SELECT *
  FROM svmc_sample_lift
  WHERE quantile_number <6
  ORDER BY quantile_number;

-- Display top probabilities  in ROC table
SELECT * FROM
  ( SELECT *
    FROM svmc_sample_roc
    ORDER BY probability
  ) WHERE ROWNUM < 6; 
   

---------
-- APPLY 
---------
  execute dm_demo_drop_object('svmc_sample_apply_prepared','view');
  execute dm_demo_drop_object('svmc_sample_apply_result','table');
  execute dm_demo_drop_object('svmc_sample_apply_ranked','table');
-- prepare apply data
BEGIN
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'svmc_sample_norm',
    data_table_name => 'mining_data_apply',
    xform_view_name => 'svmc_sample_apply_prepared');
END;
/

BEGIN
  dbms_output.put_line('Apply on apply data');
  dbms_data_mining.apply(
    model_name => 'SVM_Clas_sample',
    data_table_name => 'svmc_sample_apply_prepared',
    case_id_column_name => 'id',
    result_table_name => 'svmc_sample_apply_result');
  dbms_output.put_line('Completed apply');
END;
/

-- Display apply result
column probability format 9.99
SELECT *
  FROM (SELECT id,prediction,round(probability,4) probability
          FROM svmc_sample_apply_result
        ORDER BY id,prediction,probability )
 WHERE rownum < 11;
   
-- Rank the apply results
BEGIN
  dbms_output.put_line('Rank Apply results');
  dbms_data_mining.rank_apply (
    apply_result_table_name => 'svmc_sample_apply_result',
    case_id_column_name     => 'id',
    score_column_name => 'PREDICTION',
    score_criterion_column_name => 'PROBABILITY',
    ranked_apply_table_name => 'svmc_sample_apply_ranked',
    top_n                   => 2,
    cost_matrix_table_name  => 'svmc_cost');
END;
/

column probability format 9.99
column cost        format 9.99  
SELECT *
  FROM (SELECT id,prediction,round(probability,4) probability,
               round(cost,4) cost, rank
          FROM svmc_sample_apply_ranked
        ORDER BY id, rank)
 WHERE ROWNUM < 11;
