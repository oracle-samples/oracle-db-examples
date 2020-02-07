Rem
Rem $Header: tk_datamining/tmdm/sql/tnbdemo.sql /main/3 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem nbdemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      nbdemo.sql - Sample program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for classification function (Naive Bayes Algorithm). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    jiawang     07/22/04 - Add order by to fix sorting dif 
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    cbhagwat    10/21/03 - unbin details
Rem    ramkrish    10/17/03 - fix priors table
Rem    dmukhin     09/03/03 - name changes
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    ramkrish    06/26/03 - SET trimspool on
Rem    fcay        06/23/03 - Update copyright notices
Rem    ramkrish    06/22/03 - chg BUILD to CREATE_MODEL
Rem    cbhagwat    06/13/03 - review changes
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
  dbms_data_mining.drop_model('Naive_Bayes_Sample');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
---------------
-- CREATE MODEL
---------------
  -- Prepare mining_data_build data as appropriate
  EXECUTE dm_demo_drop_object('nb_sample_num_boundary','table');
  EXECUTE dm_demo_drop_object('nb_sample_cat_boundary','table'); 
  EXECUTE dm_demo_drop_object('nb_sample_build_prepared','view');
  EXECUTE dm_demo_drop_object('nb_sample_build_cat','view');
  EXECUTE dm_demo_drop_object('nb_sample_priors','table');
  EXECUTE dm_demo_drop_object('nb_sample_settings','table');
  
-- Create priors table
CREATE TABLE nb_sample_priors (target_value NUMBER, prior_probability NUMBER);

-- Create settings table
CREATE TABLE nb_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(30));
 
BEGIN
  -- Populate priors table
  INSERT INTO nb_sample_priors VALUES (0,0.65);
  INSERT INTO nb_sample_priors VALUES (1,0.35);

  -- Populate settings table
  INSERT INTO nb_sample_settings VALUES
    (dbms_data_mining.clas_priors_table_name, 'nb_sample_priors');
   --(dbms_data_mining.nabs_pairwise_threshold,'.01')
   --(dbms_data_mining.nabs_singleton_threshold,'.01')
  COMMIT;
  dbms_output.put_line('Populated priors and settings');
END;
/
  
-- Prepare mining_data_build data as appropriate  
BEGIN
  -- Make a numerical bin boundary table   
  dbms_data_mining_transform.create_bin_num (
    bin_table_name => 'nb_sample_num_boundary');
                         
  -- Create boundaries for age, annual_income, bulk_purch_ave_amt  (10 bins)   
  dbms_data_mining_transform.insert_bin_num_eqwidth (
    bin_table_name    => 'nb_sample_num_boundary',
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
    round_num       => 0
  );    

  -- Create boundaries for AVERAGE___ITEMS_PURCHASED, YRS_RESIDENCE 4 bins
  dbms_data_mining_transform.insert_bin_num_eqwidth (
    bin_table_name    => 'nb_sample_num_boundary',
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
    round_num       => 0
  );

  -- Bin Workclass (categorical)
  dbms_data_mining_transform.create_bin_cat (
    bin_table_name => 'nb_sample_cat_boundary');        
  dbms_data_mining_transform.insert_bin_cat_freq (
    bin_table_name    => 'nb_sample_cat_boundary',
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
    default_num       => 0);
  -- Make default bin NULL
  EXECUTE IMMEDIATE
    'DELETE FROM nb_sample_cat_boundary WHERE val IS NULL';
 
  -- Create the transformed view
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'nb_sample_cat_boundary',
    data_table_name => 'mining_data_build',
    xform_view_name => 'nb_sample_build_cat');    
  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'nb_sample_num_boundary',
    data_table_name => 'nb_sample_build_cat',
    xform_view_name => 'nb_sample_build_prepared');    
END;
/
     
-- Create Naive Bayes Model
BEGIN
  dbms_output.put_line('Invoking DBMS_DATA_MINING.CREATE_MODEL - Naive Bayes');
  dbms_data_mining.create_model(
    model_name => 'Naive_Bayes_Sample',
    mining_function => dbms_data_mining.classification,
    data_table_name => 'nb_sample_build_prepared',
    case_id_column_name => 'id',
    target_column_name => 'affinity_card',
    settings_table_name => 'nb_sample_settings');
  dbms_output.put_line('Completed Naive Bayes Build');
END;
/

-- Display the model settings   
SELECT * 
  FROM TABLE(dbms_data_mining.get_model_settings('Naive_Bayes_Sample'))
ORDER BY setting_name;

-- Display the model signature
SELECT * 
 FROM TABLE(dbms_data_mining.get_model_signature('Naive_Bayes_Sample'))
ORDER BY attribute_name;

-- Display the model details
-- Use the bin boundary tables to create labels
-- Replace attribute values with labels
-- For numeric bins, the labels are "[/(lower_boundary,upper_boundary]/)"
-- For categorical bins, label matches the value it represents
-- Note that this method of categorical label representation
-- will only work for cases where one value corresponds to one bin
-- Target was not binned, hence not unbinning it.
WITH label_view AS
(SELECT col, bin,
 Decode(bin,'1','[','(') || lv || ',' || val || ']' label
 FROM (SELECT
       col,
       bin,
       last_value(val) over (
                             PARTITION BY col
                             ORDER BY val
                             rows BETWEEN unbounded preceding
                             AND 1 preceding) lv,
       val
       FROM nb_sample_num_boundary)
 UNION ALL
 SELECT col, bin, val label  FROM nb_sample_cat_boundary
 )  
SELECT t.target_attribute_name ,
  t.target_attribute_num_value target_nval,
  t.target_attribute_str_value target_sval, 
  c.attribute_name predictor_attr,
  Nvl(l.label,
      Nvl(c.attribute_str_value,c.attribute_num_value)) predictor_val,
  t.prior_probability ,c.conditional_probability
  FROM TABLE(dbms_data_mining.get_model_details_nb('Naive_Bayes_Sample')) t,
  TABLE(t.conditionals) c,
  label_view l
  WHERE c.attribute_name = l.col (+)
  AND (Nvl(c.attribute_str_value,c.attribute_num_value) = l.bin(+) )  
ORDER BY 1,2,3,4,5,6;
--------
-- TEST
--------  
-- Prepare test data
  execute dm_demo_drop_object('nb_sample_test_apply','table');
  execute dm_demo_drop_object('nb_sample_confusion_matrix','table');
  execute dm_demo_drop_object('nb_sample_lift','table');
  execute dm_demo_drop_object('nb_sample_roc','table');
  execute dm_demo_drop_object('nb_sample_test_targets','view');
  execute dm_demo_drop_object('nb_sample_test_prepared','view');
  execute dm_demo_drop_object('nb_sample_test_cat','view');
BEGIN
   -- Create the transformed view
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'nb_sample_cat_boundary',
    data_table_name => 'mining_data_test',
    xform_view_name => 'nb_sample_test_cat');   
  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'nb_sample_num_boundary',
    data_table_name => 'nb_sample_test_cat',
    xform_view_name => 'nb_sample_test_prepared');
END;
/

-- Apply on test data
BEGIN
  dbms_output.put_line('Apply on test data');
  dbms_data_mining.apply(model_name => 'Naive_Bayes_Sample',
                data_table_name => 'nb_sample_test_prepared',
                case_id_column_name => 'id',
                result_table_name => 'nb_sample_test_apply');
  dbms_output.put_line('Completed apply on test data');
END;
/
  
-- Create Test targets view
CREATE VIEW nb_sample_test_targets AS
SELECT id, affinity_card
  FROM nb_sample_test_prepared;
DECLARE
  v_accuracy NUMBER;
  v_area_under_curve NUMBER;
BEGIN
  dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX');
  dbms_data_mining.compute_confusion_matrix (
      accuracy => v_accuracy,
      apply_result_table_name => 'nb_sample_test_apply',
      target_table_name => 'nb_sample_test_targets',
      case_id_column_name => 'id',
      target_column_name => 'affinity_card',
      confusion_matrix_table_name => 'nb_sample_confusion_matrix');
  dbms_output.put_line(
   'Confusion_matrix created in nb_sample_confusion_matrix');
  dbms_output.put_line('Accuracy: ' || v_accuracy);
   
  dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_LIFT');     
  dbms_data_mining.compute_lift (
    apply_result_table_name => 'nb_sample_test_apply',
    target_table_name => 'nb_sample_test_targets',
    case_id_column_name => 'id',
    target_column_name => 'affinity_card',
    lift_table_name => 'nb_sample_lift',
    positive_target_value => '1',
    num_quantiles => '10');
  dbms_output.put_line('Lift results created in nb_sample_lift');

  -- Compute ROC
  dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_ROC');
  dbms_data_mining.compute_roc (
    roc_area_under_curve => v_area_under_curve,
    apply_result_table_name => 'nb_sample_test_apply',
    target_table_name => 'nb_sample_test_targets',
    case_id_column_name => 'id',
    target_column_name => 'affinity_card',
    roc_table_name => 'nb_sample_roc',
    positive_target_value => '1',
    score_column_name => 'PREDICTION',
    score_criterion_column_name => 'PROBABILITY');
  dbms_output.put_line('ROC created in  nb_sample_roc');
  dbms_output.put_line('Area under the curve: ' ||v_area_under_curve );
END;
/

-- select from confusion matrix table.
SELECT * FROM nb_sample_confusion_matrix ORDER BY actual_target_value,predicted_target_value;

-- select from lift result table
--SELECT * FROM nb_sample_lift;

-- select from roc result
--SELECT * FROM nb_sample_roc;   

----------
-- APPLY
----------
  execute dm_demo_drop_object('nb_sample_apply_result','table');
  execute dm_demo_drop_object('nb_sample_apply_ranked','table');
  execute dm_demo_drop_object('nb_sample_apply_prepared','view');
  execute dm_demo_drop_object('nb_sample_apply_cat','view');

-- prepare apply data
BEGIN
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'nb_sample_cat_boundary',
    data_table_name => 'mining_data_apply',
    xform_view_name => 'nb_sample_apply_cat');   
  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'nb_sample_num_boundary',
    data_table_name => 'nb_sample_apply_cat',
    xform_view_name => 'nb_sample_apply_prepared');
END;
/

BEGIN
  dbms_output.put_line('Apply on apply data');
  dbms_data_mining.apply(
    model_name => 'Naive_Bayes_Sample',
    data_table_name => 'nb_sample_apply_prepared',
    case_id_column_name => 'id',
    result_table_name => 'nb_sample_apply_result');
  dbms_output.put_line('Completed apply');
END;
/

-- Display apply result
SELECT *
  FROM (SELECT id,prediction,Round(probability,4) probability
          FROM nb_sample_apply_result
        ORDER BY id, prediction,probability )
 WHERE rownum < 11;
   
-- Rank the apply results
BEGIN
  dbms_output.put_line('Rank Apply results');
  dbms_data_mining.rank_apply (
    apply_result_table_name => 'nb_sample_apply_result',
    case_id_column_name     => 'id',
    score_column_name => 'PREDICTION',
    score_criterion_column_name => 'PROBABILITY',
    ranked_apply_table_name => 'nb_sample_apply_ranked',
    top_n                   => 1);
END;
/

SELECT *
  FROM (SELECT id, prediction, Round(probability,4) probability,
               Round(cost,4) cost, rank
          FROM nb_sample_apply_ranked
        ORDER BY id,rank)
 WHERE ROWNUM < 11;
