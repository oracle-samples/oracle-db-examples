Rem
Rem $Header: tk_datamining/tmdm/sql/tabndemo.sql /main/7 2010/11/04 13:28:39 xbarr Exp $
Rem
Rem abndemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      abndemo.sql - Sample program for DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for classification function (ABN Algorithm). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       10/25/10 - binary_double formatting
Rem    jiawang     06/14/06 - Fix bug 6141493
Rem    jiawang     06/14/06 - Add 'order by' to display setting
Rem    cbhagwat    05/17/05 - fix reproducibility issue 
Rem    ramkrish    03/03/05 - 1832754 - order model details based on rule_id 
Rem                           and mask rule_id 
Rem    ramkrish    07/29/04 - remove masking 
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    cbhagwat    11/14/03 - Single feature model
Rem    cbhagwat    10/21/03 - unbin
Rem    cbhagwat    10/20/03 - Label bins
Rem    dmukhin     09/02/03 - name changes
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    ramkrish    06/26/03 - 
Rem    ramkrish    06/26/03 - SET trimspool on
Rem    fcay        06/23/03 - Update copyright notices
Rem    ramkrish    06/22/03 - chg BUILD to CREATE_MODEL
Rem    cbhagwat    06/16/03 - review changes
Rem    cbhagwat    06/10/03 - mining_data changes
Rem    cbhagwat    05/29/03 - dbms_dm_xform => dbms_data_mining_transform
Rem    cbhagwat    05/20/03 - remove precision_recall
Rem    cbhagwat    05/03/03 - Creation
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000

-- For signature
 column attribute_type format a20
  
-- Drop objects, ignore exceptions
-- This procedure is used below - to ensure successful
-- re-execution of the demo programs
CREATE OR REPLACE
PROCEDURE dm_demo_drop_object (object_name VARCHAR2, object_type VARCHAR2) IS
  v_drop_stmt VARCHAR2(100):= 'DROP ' || object_type || ' ' || object_name;
BEGIN
  EXECUTE IMMEDIATE v_drop_stmt;
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/
    
BEGIN 
  -- Drop the model
  dbms_data_mining.drop_model('ABN_Clas_sample');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
    
---------------
-- CREATE MODEL
---------------
  
-- Create settings table
  execute dm_demo_drop_object('abn_sample_settings','table');
CREATE TABLE abn_sample_settings
  (setting_name VARCHAR2(30),
   setting_value VARCHAR2 (30));
 
BEGIN       
  -- Populate settings table
  INSERT INTO abn_sample_settings VALUES
    (dbms_data_mining.algo_name,
     dbms_data_mining.algo_adaptive_bayes_network);
  INSERT INTO abn_sample_settings VALUES
    (dbms_data_mining.abns_model_type,
     dbms_data_mining.abns_single_feature);
  
  --(dbms_data_mining.abns_max_build_minutes,0);
  --(dbms_data_mining.abns_max_nb_predictors,10);
  --(dbms_data_mining.abns_max_predictors,25);
  COMMIT;
  dbms_output.put_line('Populated settings');
END;
/

-- Prepare mining_data_build data as appropriate  
  execute dm_demo_drop_object('abn_sample_num_boundary','table');
  execute dm_demo_drop_object('abn_sample_cat_boundary','table');
  execute dm_demo_drop_object('abn_sample_build_prepared','view');
  execute dm_demo_drop_object('abn_sample_build_cat','view');
  
BEGIN
  -- Make a numerical bin boundary table   
  dbms_data_mining_transform.create_bin_num (
    bin_table_name => 'abn_sample_num_boundary');
                         
  -- Create boundaries for age, annual_income, bulk_purch_ave_amt (10 bins)
  dbms_data_mining_transform.insert_bin_num_eqwidth (
    bin_table_name    => 'abn_sample_num_boundary',
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
    bin_table_name    => 'abn_sample_num_boundary',
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
  -- Update the BIN column with labels (By default, the bins get 1...N)
  -- We will update the "BIN" column to contain "[/(Lower-bound,Upper-bound)/]"
  --
  EXECUTE IMMEDIATE 
    'UPDATE abn_sample_num_boundary o SET bin =' ||
    '(SELECT Decode(bin,''1'',''['',''('') || lv || '','' || val || '']'' ' ||
     ' FROM ( SELECT col, bin, ' ||
     '       last_value(val) over ( ' ||
     '                             PARTITION BY col ' ||
     '                             ORDER BY val ' ||
     '                             rows BETWEEN unbounded preceding ' ||
     '                             AND 1 preceding) lv, ' ||
     '       val ' ||
     '       from  abn_sample_num_boundary ) b ' ||
     ' WHERE b.col = o.col AND b.val = o.val) ' ||
     ' WHERE bin IS NOT null';
  
  -- Bin Workclass (categorical)
  dbms_data_mining_transform.create_bin_cat (
    bin_table_name => 'abn_sample_cat_boundary');        

  dbms_data_mining_transform.insert_bin_cat_freq (
    bin_table_name    => 'abn_sample_cat_boundary',
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
    'DELETE FROM abn_sample_cat_boundary WHERE val IS NULL';
  --
  -- Update the bin to conatin the Value it represents
  -- (instead of default 1..N)
  EXECUTE IMMEDIATE 'UPDATE abn_sample_cat_boundary SET BIN=VAL'; 
  COMMIT;    
  -- Create the transformed view
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'abn_sample_cat_boundary',
    data_table_name => 'mining_data_build',
    xform_view_name => 'abn_sample_build_cat');    

  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'abn_sample_num_boundary',
    data_table_name => 'abn_sample_build_cat',
    xform_view_name => 'abn_sample_build_prepared');    
END;
/
       
-- Create ABN Model
BEGIN
  dbms_output.put_line(
   'Invoking DBMS_DATA_MINING.CREATE_MODEL - ABN - Classification');
  dbms_data_mining.create_model(
    model_name => 'ABN_Clas_sample',
    mining_function => dbms_data_mining.classification,
    data_table_name => 'abn_sample_build_prepared',
    case_id_column_name => 'id',
    target_column_name => 'affinity_card',
    settings_table_name => 'abn_sample_settings');
  dbms_output.put_line('Completed ABN - Classification Build');
END;
/
    
-- Display the model settings   
SELECT *
  FROM TABLE(dbms_data_mining.get_model_settings('ABN_Clas_sample')) order by SETTING_NAME;

-- Display the model signature
SELECT *
  FROM TABLE(dbms_data_mining.get_model_signature('ABN_Clas_sample'))
ORDER BY attribute_name;

-- get_model_details_abn
SET serveroutput ON;
SET line 120;
DECLARE
  v_antecedents dm_predicates ;
  v_consequents dm_predicates ;
  v_rule_id     NUMBER;
  v_rule_support NUMBER;
  v_consequent_support NUMBER;
  v_num_consequents NUMBER;
  v_num_antedents NUMBER;
  TYPE rule_cursor_type IS ref CURSOR;
  v_if_clause VARCHAR2(4000);
  v_then_clause VARCHAR2(4000);
  v_rule_cursor rule_cursor_type;
BEGIN
  dbms_output.enable(10000000);
  OPEN v_rule_cursor FOR
    'select rule_id,rule_support, ' ||
    'antecedent, consequent from ' ||
    'table(dbms_data_mining.get_model_details_abn(''abn_clas_sample''))' ||
    ' where rule_support >0.002 order by rule_support desc';
  LOOP 
    FETCH v_rule_cursor
      INTO v_rule_id,v_rule_support,v_antecedents,v_consequents;
    EXIT WHEN v_rule_cursor%notfound;
     v_if_clause := 'IF ';
    v_num_antedents := v_antecedents.COUNT;
    -- Form antecedent string
    FOR i IN 1..v_num_antedents
      LOOP
	v_if_clause := v_if_clause || v_antecedents(i).attribute_name ||
	  ' ' || v_antecedents(i).conditional_operator ||
	  ' ' || Nvl(v_antecedents(i).attribute_str_value,
		     v_antecedents(i).attribute_num_value);
	IF i < v_num_antedents THEN
	  v_if_clause := v_if_clause || ' AND ';
	END IF;
      END LOOP;
      
    v_then_clause := 'THEN ';
    v_num_consequents := v_consequents.COUNT;
    -- Form consequent string
    FOR i IN 1..v_num_consequents
      LOOP
	v_then_clause := v_then_clause || v_consequents(i).attribute_name ||
	  ' ' || v_consequents(i).conditional_operator ||
	  ' ' || Nvl(v_consequents(i).attribute_str_value,
		     v_consequents(i).attribute_num_value) ||
	  ' Confidence (' ||
	  To_char( v_consequents(i).attribute_confidence,'9.99') || ')';
	IF i < v_num_consequents THEN
	  v_then_clause := v_then_clause || ' AND ';
	END IF;
      END LOOP;     
--      dbms_output.put_line('Rule ID: ' || v_rule_id );
      dbms_output.put_line('Rule Support: '
			   || To_char(v_rule_support,'9.999'));
      dbms_output.put_line( v_if_clause);
      dbms_output.put_line( v_then_clause);
  END LOOP;
  
END;
/

-------------
-- TEST MODEL
-------------
  execute dm_demo_drop_object('abn_sample_test_apply','table');
  execute dm_demo_drop_object('abn_sample_confusion_matrix','table');
  execute dm_demo_drop_object('abn_sample_lift','table');
  execute dm_demo_drop_object('abn_sample_roc','table');
  execute dm_demo_drop_object('abn_sample_test_targets','view');
  execute dm_demo_drop_object('abn_sample_test_prepared','view');
  execute dm_demo_drop_object('abn_sample_test_cat','view');
  
-- prepare test data
BEGIN
  -- Create the transformed view
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'abn_sample_cat_boundary',
    data_table_name => 'mining_data_test',
    xform_view_name => 'abn_sample_test_cat');   
  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'abn_sample_num_boundary',
    data_table_name => 'abn_sample_test_cat',
    xform_view_name => 'abn_sample_test_prepared');
END;
/

-- Apply model on test data
   execute dm_demo_drop_object('abn_sample_apply_result','table');
   execute dm_demo_drop_object('abn_sample_apply_ranked','table');
   execute dm_demo_drop_object('abn_sample_apply_prepared','view');
   execute dm_demo_drop_object('abn_sample_apply_cat','view');    
BEGIN
  dbms_output.put_line('Apply on test data');
  dbms_data_mining.apply(
    model_name => 'ABN_Clas_sample',
    data_table_name => 'abn_sample_test_prepared',
    case_id_column_name => 'id',
    result_table_name => 'abn_sample_test_apply');
  dbms_output.put_line('Completed apply on test data');
END;
/

-- Create Test targets view
CREATE VIEW abn_sample_test_targets AS
SELECT id, affinity_card
  FROM abn_sample_test_prepared;

-- Test the model
VARIABLE v_accuracy NUMBER
VARIABLE v_area_under_curve NUMBER
DECLARE
  v_accuracy NUMBER;
  v_area_under_curve NUMBER;
 BEGIN
   dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX');
   dbms_data_mining.compute_confusion_matrix (
     accuracy => :v_accuracy,
     apply_result_table_name => 'abn_sample_test_apply',
     target_table_name => 'abn_sample_test_targets',
     case_id_column_name => 'id',
     target_column_name => 'affinity_card',
     confusion_matrix_table_name => 'abn_sample_confusion_matrix',
     score_column_name      => 'PREDICTION',
     score_criterion_column_name => 'PROBABILITY');
   dbms_output.put_line(
     'Confusion_matrix created in abn_sample_confusion_matrix');
   dbms_output.put_line('Accuracy: ' || TO_CHAR(:v_accuracy,'9.99EEEE'));
 
   dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_LIFT');     
   dbms_data_mining.compute_lift (
     apply_result_table_name => 'abn_sample_test_apply',
     target_table_name => 'abn_sample_test_targets',
     case_id_column_name => 'id',
     target_column_name => 'affinity_card',
     lift_table_name => 'abn_sample_lift',
     positive_target_value => '1',
     num_quantiles => '10');
   dbms_output.put_line('Lift results created in abn_sample_lift');

   -- Compute ROC
   dbms_output.put_line('Invoke DBMS_DATA_MINING.COMPUTE_ROC');
   dbms_data_mining.compute_roc (
     roc_area_under_curve => :v_area_under_curve,
     apply_result_table_name => 'abn_sample_test_apply',
     target_table_name => 'abn_sample_test_targets',
     case_id_column_name => 'id',
     target_column_name => 'affinity_card',
     roc_table_name => 'abn_sample_roc',
     positive_target_value => '1',
     score_column_name => 'PREDICTION',
     score_criterion_column_name => 'PROBABILITY');
   dbms_output.put_line('ROC created in  abn_sample_roc');
   dbms_output.put_line('Area under the curve: ' || TO_CHAR(:v_area_under_curve,'9.99EEEE'));
 END;
 /

-- Display confusion matrix table.
SELECT *
  FROM abn_sample_confusion_matrix
ORDER BY actual_target_value,predicted_target_value;

-- Display lift result table
column PROBABILITY_THRESHOLD format 9.999999999
SELECT *
  FROM abn_sample_lift order by quantile_number;

-- select from roc result
column PROBABILITY format 9.999999999
SELECT *
  FROM abn_sample_roc order by probability;

--------------
-- APPLY MODEL
--------------
-- prepare apply data
BEGIN
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'abn_sample_cat_boundary',
    data_table_name => 'mining_data_apply',
    xform_view_name => 'abn_sample_apply_cat');   
  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'abn_sample_num_boundary',
    data_table_name => 'abn_sample_apply_cat',
    xform_view_name => 'abn_sample_apply_prepared');
END;
/

-- Apply
BEGIN
  dbms_output.put_line('Apply on apply data');
  dbms_data_mining.apply(
    model_name => 'ABN_Clas_sample',
    data_table_name => 'abn_sample_apply_prepared',
    case_id_column_name => 'id',
    result_table_name => 'abn_sample_apply_result');
  dbms_output.put_line('Completed apply');
END;
/

-- Display apply result
SELECT *
  FROM (SELECT id, prediction, Round(probability,4) probability
          FROM abn_sample_apply_result
        ORDER BY  id, prediction,probability)
 WHERE rownum < 11;
   
-- Rank the apply results
BEGIN
  dbms_output.put_line('Rank Apply results');
  dbms_data_mining.rank_apply (
    apply_result_table_name => 'abn_sample_apply_result',
    case_id_column_name     => 'id',
    score_column_name => 'PREDICTION',
    score_criterion_column_name => 'PROBABILITY',
    ranked_apply_table_name => 'abn_sample_apply_ranked',
    top_n                   => 2);
END;
/

SELECT *
  FROM (SELECT id, prediction, Round(probability,4) probability, rank
          FROM abn_sample_apply_ranked
        ORDER BY id, rank)
 WHERE rownum < 11;
