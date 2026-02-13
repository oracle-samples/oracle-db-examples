-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   Partitioned Models - Support Vector Machine Algorithm - dmpartdemo.sql
--   
--   Copyright (c) 2026 Oracle Corporation and/or its affilitiates.
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
SET serveroutput ON
SET pages 10000

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic data about a set of customers, predict the
-- customer response to an affinity card program using a SVM
-- classifier whose model is partitioned. 

-------------------
-- SPECIFY SETTINGS
-------------------
-- Cleanup old settings table with the same name for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE part_clas_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create settings table to choose linear kernel
CREATE TABLE part_clas_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
 
BEGIN
  -- Populate settings table
  INSERT INTO part_clas_settings VALUES
    (dbms_data_mining.algo_name,
     dbms_data_mining.algo_support_vector_machines);
  INSERT INTO part_clas_settings VALUES
    (dbms_data_mining.prep_auto, dbms_data_mining.prep_auto_on);
  INSERT INTO part_clas_settings VALUES
    (dbms_data_mining.svms_kernel_function,dbms_data_mining.svms_linear);
  -- partition column: GENDER
  INSERT INTO part_clas_settings VALUES
    (dbms_data_mining.odms_partition_columns, 'CUST_GENDER');
  COMMIT;
END;
/

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------
-- Cleanup old model with the same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('part_clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Build a new partitioned SVM model
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'part_clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_parallel_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'part_clas_settings');
END;
/

-- Display the model settings
column setting_name format a30;
column setting_value format a30;
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'PART_CLAS_SAMPLE'
ORDER BY setting_name;

-- Display the model signature
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
  FROM user_mining_model_attributes
 WHERE model_name = 'PART_CLAS_SAMPLE'
ORDER BY attribute_name;

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='PART_CLAS_SAMPLE'
  ORDER BY view_name;

-- Display the top ten model details per partition
set long 20000
column class format 9999
column aname format a25
column aval  format a25
column coeff format 9.999
-- for male customers
SELECT target_value class, attribute_name aname, attribute_value aval, coefficient coeff
FROM (SELECT target_value, attribute_name, attribute_value, coefficient
  FROM DM$VLPART_CLAS_SAMPLE WHERE partition_name = 
  (SELECT ORA_DM_PARTITION_NAME(PART_CLAS_SAMPLE using 'M' CUST_GENDER) FROM dual)
  ORDER BY coefficient DESC) 
WHERE ROWNUM <= 10;
-- for female customers
SELECT target_value class, attribute_name aname, attribute_value aval, coefficient coeff
FROM (SELECT target_value, attribute_name, attribute_value, coefficient
  FROM DM$VLPART_CLAS_SAMPLE WHERE partition_name = 
  (SELECT ORA_DM_PARTITION_NAME(PART_CLAS_SAMPLE using 'F' CUST_GENDER) FROM dual)
  ORDER BY coefficient DESC) 
WHERE ROWNUM <= 10;

-- Add another partition column 
UPDATE part_clas_settings SET setting_value = 'CUST_GENDER,CUST_INCOME_LEVEL'
  WHERE setting_name = 'ODMS_PARTITION_COLUMNS';

-- Cleanup old model with the same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('part2_clas_sample');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Build another partitioned model with two partition columns
-- with three partition values for CUST_INCOME_LEVEL
DECLARE
  xform_list dbms_data_mining_transform.TRANSFORM_LIST;
BEGIN
  dbms_data_mining_transform.set_transform(xform_list,
    'CUST_INCOME_LEVEL', null, 
    'CASE CUST_INCOME_LEVEL WHEN ''A: Below 30,000'' THEN ''LOW'' 
    WHEN ''L: 300,000 and above'' THEN ''HIGH'' 
    ELSE ''MEDIUM'' END', null);
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'part2_clas_sample',
    mining_function     => dbms_data_mining.classification,
    data_table_name     => 'mining_data_build_parallel_v',
    case_id_column_name => 'cust_id',
    target_column_name  => 'affinity_card',
    settings_table_name => 'part_clas_settings',
    xform_list          => xform_list);
END;
/

-- Display model details for partition: 'F','MEDIUM'
SELECT target_value class, attribute_name aname, attribute_value aval, coefficient coeff
FROM (SELECT target_value, attribute_name, attribute_value, coefficient
  FROM DM$VLPART2_CLAS_SAMPLE WHERE partition_name = 
  (SELECT ORA_DM_PARTITION_NAME(PART2_CLAS_SAMPLE USING 
  'F' CUST_GENDER, 'MEDIUM' CUST_INCOME_LEVEL) FROM dual)
  ORDER BY coefficient DESC) 
WHERE ROWNUM <= 10;


-----------------------------------------------------------------------
--                               TEST THE MODEL
--                SCORE NEW DATA USING SQL DATA MINING FUNCTIONS
-----------------------------------------------------------------------

------------------
-- BUSINESS CASE 1
--
-- Find the three male and five female customers that are most likely 
-- to use an affinity card.
-- Also explain why they are likely to use an affinity card.
-- /*+ GROUPING */ hint forces scoring to be done completely 
-- for each partition before advancing to the next partition.
-- GROUPING is especially beneficial when partitions altogether
-- do not fit into fast memory.
column gender format a1
column income format a30
column rnk format 9
SELECT cust_id, cust_gender as gender, rnk, pd FROM
( SELECT cust_id, cust_gender,
    PREDICTION_DETAILS(/*+ GROUPING */ PART_CLAS_SAMPLE, 1 USING *) pd,
    rank() over (partition by cust_gender order by 
    PREDICTION_PROBABILITY(PART_CLAS_SAMPLE, 1 USING *) desc, cust_id) rnk
  FROM mining_data_apply_parallel_v)
WHERE rnk <= 3 
order by rnk, cust_gender;

------------------
-- BUSINESS CASE 2
-- Find the average age of customers who are likely to use an
-- affinity card. Break out the results by gender.
--
SELECT cust_gender as gender,
       COUNT(*) AS cnt,
       ROUND(AVG(age)) AS avg_age
FROM mining_data_apply_parallel_v
WHERE PREDICTION(PART_CLAS_SAMPLE USING *) = 1
GROUP BY cust_gender ORDER BY cust_gender;

-- compare with the average age of all customers
SELECT cust_gender,
       COUNT(*) AS cnt,
       ROUND(AVG(age)) AS avg_age
  FROM mining_data_apply_parallel_v
GROUP BY cust_gender ORDER BY cust_gender;

-- find the average age of predicted card users per gender and income
-- for the groups containing statistically sufficient data
-- using model PART2_CLAS_SAMPLE with two partition columns
SELECT cust_gender as gender, cust_income_level as income, avg_age FROM
  (SELECT cust_gender, cust_income_level,
    COUNT(*) AS cnt,
    ROUND(AVG(age)) AS avg_age
  FROM mining_data_apply_parallel_v
  WHERE PREDICTION(PART2_CLAS_SAMPLE USING *) = 1  
  GROUP BY cust_gender, cust_income_level)
WHERE cnt > 10 -- throw out the groups with fewer than 10 people
ORDER BY cust_gender, cust_income_level;

------------------
-- BUSINESS CASE 3
-- Calculate prediction accuracy per gender (expressed in percents).
-- Expand the model and re-calculate the accuracy
--
column percent format 99
SELECT t.cust_gender as gender, round(cnt/total*100) as percent FROM 
(SELECT cust_gender, COUNT(*) AS cnt FROM mining_data_apply_parallel_v
  WHERE PREDICTION(PART_CLAS_SAMPLE USING *) = AFFINITY_CARD 
  GROUP BY cust_gender) p,
(SELECT cust_gender, COUNT(*) AS total FROM mining_data_apply_parallel_v 
  GROUP BY cust_gender) t
WHERE p.cust_gender = t.cust_gender ORDER BY t.cust_gender;

-- Suppose we have additional training data with an unknown gender
-- For that purpose, we duplicate mining_data_build_v 
-- with gender set to 'unknown' and ID set to a negative value
CREATE OR replace VIEW ext_mining_data_build_v AS
(SELECT -CUST_ID as CUST_ID, 'U' as CUST_GENDER, AGE, 
  CUST_MARITAL_STATUS, COUNTRY_NAME,
  CUST_INCOME_LEVEL, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE,
  YRS_RESIDENCE, AFFINITY_CARD, BULK_PACK_DISKETTES, FLAT_PANEL_MONITOR,
  HOME_THEATER_PACKAGE, BOOKKEEPING_APPLICATION, PRINTER_SUPPLIES,
  Y_BOX_GAMES, OS_DOC_SET_KANJI
  FROM mining_data_build_parallel_v);

-- Now we can add these data as a new partition to model PART_CLAS_SAMPLE
BEGIN
dbms_data_mining.add_partition('PART_CLAS_SAMPLE',
'SELECT * FROM ext_mining_data_build_v', 'error');
END;
/

-- And we similarly duplicate mining_data_apply_v 
CREATE OR replace VIEW ext_mining_data_apply_v AS 
SELECT -CUST_ID as CUST_ID, 'U' as CUST_GENDER, AGE, CUST_MARITAL_STATUS, 
  COUNTRY_NAME, CUST_INCOME_LEVEL, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE,
  YRS_RESIDENCE, AFFINITY_CARD, BULK_PACK_DISKETTES, FLAT_PANEL_MONITOR,
  HOME_THEATER_PACKAGE, BOOKKEEPING_APPLICATION, PRINTER_SUPPLIES,
  Y_BOX_GAMES, OS_DOC_SET_KANJI
  FROM mining_data_apply_parallel_v
UNION
SELECT * FROM mining_data_apply_parallel_v;

-- Re-calculate prediction accuracy per gender 
-- including data with unknown gender
SELECT t.cust_gender as gender, round(cnt/total*100) as percent FROM 
(SELECT cust_gender, COUNT(*) AS cnt FROM ext_mining_data_apply_v
  WHERE PREDICTION(PART_CLAS_SAMPLE USING *) = AFFINITY_CARD 
  GROUP BY cust_gender) p,
(SELECT cust_gender, COUNT(*) AS total FROM ext_mining_data_apply_v 
  GROUP BY cust_gender) t
WHERE p.cust_gender = t.cust_gender ORDER BY t.cust_gender;

