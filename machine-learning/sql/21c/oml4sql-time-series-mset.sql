-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 21c
-- 
--   Time Series - Multivariate State Estimation Technique Algorithm - dmmsetdemo.sql
--   
--   Copyright (c) 2021 Oracle Corporation and/or its affilitiates.
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
  
-----------------------------------------------------------------------  
--  MSET-SPRT algorithm for multi-variate time-series anomaly detection
-----------------------------------------------------------------------
--                      SAMPLE PROBLEM
--  Given the two-variate time series data, the daily sold 
--  quantity and amount from January 1, 1998 to December 31, 1999, 
--  predict the anomalies of sold data from January 1, 2000 to  
--  December 31 2001.
-----------------------------------------------------------------------  
--                     (1)   SET UP THE DATA
--  The data for this sample is from SH Schema, specifically, subtables 
--  of sh.sales.
--  Two views are created based on sh.sales:
--  mset_build_sh_data (build data)
--  mset_test_sh_data  (test data)
-----------------------------------------------------------------------
-- Cleanup old settings table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE mset_sh_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Cleanup old model with the same name
BEGIN DBMS_DATA_MINING.DROP_MODEL('MSET_SH_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create training multivariate time series data from year 1998 and 1999
CREATE OR replace VIEW mset_build_sh_data 
  AS SELECT time_id, sum(quantity_sold) quantity, 
  sum(amount_sold) amount from (SELECT * FROM sh.sales WHERE 
  time_id <= '30-DEC-99') GROUP BY time_id ORDER BY time_id;
       
-- Create testing multivariate time series data from year 2000-2001 
CREATE OR replace VIEW mset_test_sh_data 
  AS SELECT time_id, sum(quantity_sold) quantity, sum(amount_sold) 
    amount FROM (SELECT * FROM sh.sales WHERE time_id > '30-DEC-99') 
    GROUP BY time_id ORDER BY time_id;      
              
-- Create setting table        
CREATE TABLE mset_sh_settings(setting_name VARCHAR2(30), 
                             setting_value VARCHAR2(128));
-- Populate setting table
BEGIN
  -- Select MSET-SPRT as the algorithm
  INSERT  INTO mset_sh_settings
         VALUES(dbms_data_mining.algo_name,
                dbms_data_mining.algo_mset_sprt);
  -- Turn on automatic data preparation   
  INSERT INTO mset_sh_settings
         VALUES(dbms_data_mining.prep_auto,
                dbms_data_mining.prep_auto_on);
  -- Set memory vector
  INSERT INTO mset_sh_settings
    VALUES(dbms_data_mining.mset_memory_vectors, 100);
  -- Set alpha
  INSERT INTO mset_sh_settings
    VALUES(dbms_data_mining.MSET_ALPHA_PROB, 0.1);
  -- Set alert count
  INSERT INTO mset_sh_settings
    VALUES(dbms_data_mining.MSET_ALERT_COUNT, 3);
  -- Set alert window
  INSERT INTO mset_sh_settings
    VALUES(dbms_data_mining.MSET_ALERT_WINDOW, 5);  
  -- Examples of other possible settings are:
  -- (dbms_data_mining.mset_beta_prob, 0.1)
  -- (dbms_data_mining.mset_adb_height, 0.01)
  -- (dbms_data_mining.mset_std_tolerance, 3)
  -- (dbms_data_mining.mset_heldaside, 500)
  commit;  
END;
/

-----------------------------------------------------------------
--                (2)  Build the MSET model
-----------------------------------------------------------------
BEGIN
  dbms_data_mining.create_model(model_name => 'MSET_SH_MODEL',
               mining_function   => 'CLASSIFICATION',
               data_table_name => 'mset_build_sh_data',
               case_id_column_name => 'time_id',
               target_column_name => '',
               settings_table_name => 'MSET_SH_SETTINGS');
END;
/

------------------------
-- DISPLAY MODEL SETTINGS
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'MSET_SH_MODEL'
ORDER BY setting_name;

-------------------------
-- DISPLAY MODEL SIGNITURE
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
FROM   user_mining_model_attributes
  WHERE  model_name = 'MSET_SH_MODEL'
  ORDER BY attribute_name;

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='MSET_SH_MODEL'
  ORDER BY view_name;

-- get global diagnostics
column name format a20
column numeric_value format a20
column string_value format a15
SELECT name, 
to_char(numeric_value, '99999') numeric_value, 
string_value FROM DM$VGMSET_SH_MODEL
  ORDER BY name;

-----------------------------------------------------------------------
--                         (3)   TEST THE MODEL
-----------------------------------------------------------------------
-- Predicting anomalies of daily sold data from year 2000 to 2001
-----------------------------------------------------------------------
-- display predictions and probabilities of a sample list of data
col prob format 0.999   
col pred format 9999
col time_id format a20  
SELECT time_id, prediction(mset_sh_model using *) over 
  (ORDER BY time_id) pred, prediction_probability (mset_sh_model using *) 
  over (ORDER BY time_id) prob
  FROM (SELECT * FROM mset_test_sh_data  WHERE time_id > '15-DEC-01' AND 
  time_id <= '25-DEC-01' ) ORDER BY time_id;

-- display all dates of year 2000 to 2001 when anomalies occur
SELECT time_id, pred FROM (SELECT time_id, prediction(mset_sh_model using *) 
  over (ORDER BY time_id) pred FROM mset_test_sh_data) WHERE pred = 0;  

-- display total anomaly count for year 2000 to 2001
col min(prob) format 0.999
col max(prob) format 0.999
SELECT pred, count(pred), min(prob), max(prob) FROM (
  SELECT prediction(mset_sh_model using *) over (ORDER BY time_id) pred, 
  prediction_probability(mset_sh_model using *) over (ORDER BY time_id) 
  prob FROM mset_test_sh_data ) GROUP BY pred ORDER BY pred;

-- display anomly rate: number of anomaly/total number of data
col anomalyrate format 9.999
SELECT 1-sum(correct)/count(*) AS anomalyrate
  FROM (SELECT decode(prediction(mset_sh_model using *) over 
  (ORDER BY time_id), 1, 1) AS correct FROM mset_test_sh_data );
  
-- display prediction details 
SET long 1000;  
col anomalydetails format a80
SELECT time_id, prediction(mset_sh_model using *) over (ORDER BY time_id) 
  pred, prediction_details(mset_sh_model using *) over (ORDER BY time_id) 
  anomalyDetails FROM mset_test_sh_data  WHERE time_id > '15-DEC-01' AND 
  time_id <= '25-DEC-01' ORDER BY time_id;
  
 
