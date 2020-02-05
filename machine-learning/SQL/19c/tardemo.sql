Rem
Rem $Header: tk_datamining/tmdm/sql/tardemo.sql /main/4 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem ardemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      ardemo.sql - Sample program for DBMS_DATA_MINING package.  
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING
Rem      for association function (Apriori Algorithm). 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    dmukhin     12/13/06 - bug 5557333: AR scoping
Rem    ramkrish    08/02/04 - lrg 1726339 - comment out itemsetid 
Rem                           hash-based group by no longer guarantees
Rem                           ordered itemset id's
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    mmcracke    12/11/03 - Remove Rule ID from result display
Rem    pstengar    10/13/03 - Fixed ordering of itemsets for reproducibility
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    ramkrish    06/26/03 - SET trimspool on
Rem    fcay        06/23/03 - Update copyright notices
Rem    ramkrish    06/22/03 - chg BUILD to CREATE_MODEL
Rem    cbhagwat    06/16/03 - use market basket data
Rem    cbhagwat    06/16/03 - review changes
Rem    cbhagwat    06/10/03 - mining_data changes
Rem    cbhagwat    06/06/03 - get rules changes
Rem    cbhagwat    05/29/03 - dbms_dm_xform => dbms_data_mining_transform
Rem    cbhagwat    04/17/03 - parameter names: removed p_
Rem    cbhagwat    04/14/03 - Changes
Rem    cbhagwat    02/25/03 - Creation

SET serveroutput ON
SET trimspool ON
SET pages 10000

BEGIN
  -- Drop the model
  dbms_data_mining.drop_model('Association_Rules_Sample');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

---------------
-- CREATE MODEL
---------------

  execute dm_demo_drop_object('ar_sample_settings','table');
-- Create a settings table
CREATE TABLE ar_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(128));

-- Set max rule length to 2
BEGIN
  INSERT INTO ar_sample_settings VALUES
    (dbms_data_mining.asso_max_rule_length,3);
  --(dbms_data_mining.asso_min_confidence,0.1);
  --(dbms_data_mining.asso_min_support,0.1);
  COMMIT;
END;
/    

-- Create Association Rules model
BEGIN
  dbms_output.put_line(
   'Invoking DBMS_DATA_MINING.CREATE_MODEL - Association Rules');
  dbms_data_mining.create_model(
    model_name => 'Association_Rules_Sample',
    mining_function => dbms_data_mining.association,
    data_table_name => 'market_basket_2d_binned',
    case_id_column_name => 'id',
    settings_table_name => 'ar_sample_settings');
  dbms_output.put_line('Completed Association Rules Build');
END;
/
   
-- Display the settings
SELECT *
  FROM TABLE(dbms_data_mining.get_model_settings('Association_Rules_Sample'))
ORDER BY setting_name;

-- Display formatted model details
SET heading off;
break ON rule_id,rule_support,rule_confidence;
break ON antecedent,consequent;
break ON antecedent_support,consequent_support;

SELECT 'Rule Support: ' || t.rule_support rule_support,
--      ' Rule Id: ' || t.rule_id rule_id ,   
      ' Rule Confidence: ' || t.rule_confidence rule_confidence,    
      ' Antecedent attribute:' || ante.attribute_name  || 
       ante.conditional_operator || 
       Nvl(ante.attribute_str_value,ante.attribute_num_value) antecedent,       
      ' Consequent attribute:' || cons.attribute_name ||
       cons.conditional_operator ||
       Nvl(cons.attribute_str_value,cons.attribute_num_value) consequent,    
     ' Antecedent support: ' || ante.attribute_support antecedent_support,
     ' Consequent support: ' || cons.attribute_support
      consequent_support
 FROM TABLE(
      dbms_data_mining.get_association_rules('Association_Rules_Sample')) t,
      TABLE(t.antecedent) ante,
      TABLE(t.consequent) cons
ORDER BY 1 DESC,2,3,4,5,6;

SET head ON;

-- Display itemsets
SET heading on;
break ON itemset_id skip 1;
-- SELECT t.itemset_id, i.column_value AS item,
SELECT nvl(i.attribute_subname, i.attribute_name)||'-'||
       nvl(i.attribute_str_value,
           to_char(i.attribute_num_value)) AS item,
       t.support, t.number_of_items
  FROM TABLE(
       dbms_data_mining.get_frequent_itemsets('Association_Rules_Sample')) t,
       TABLE(t.items) i
ORDER BY number_of_items,support,item;
