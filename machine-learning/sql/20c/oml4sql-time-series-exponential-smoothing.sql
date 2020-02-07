-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL)
-- 
--   Time Series - Exponential Smoothing Algorithm - dmesmdemo.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

-----------------------------------------------------------------------
--                            SET UP THE DATA
-----------------------------------------------------------------------
-- Cleanup old settings table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE esm_sh_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Cleanup old model with the same name
BEGIN DBMS_DATA_MINING.DROP_MODEL('ESM_SH_SAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create input time series
create or replace view esm_sh_data 
       as select time_id, amount_sold 
       from sh.sales;

CREATE TABLE esm_sh_settings(setting_name VARCHAR2(30), 
                             setting_value VARCHAR2(128));
begin
  -- Select ESM as the algorithm
  insert into esm_sh_settings 
         values(dbms_data_mining.algo_name,
                dbms_data_mining.algo_exponential_smoothing);
  -- Set accumulation interval to be quarter
  insert into esm_sh_settings 
         values(dbms_data_mining.exsm_interval,
                dbms_data_mining.exsm_interval_qtr);
  -- Set prediction step to be 4 quarters (one year)
  INSERT INTO esm_sh_settings 
         VALUES(dbms_data_mining.exsm_prediction_step,
                '4');
  -- Set ESM model to be Holt-Winters
  INSERT INTO esm_sh_settings 
         VALUES(dbms_data_mining.exsm_model,
                dbms_data_mining.exsm_hw);
  -- Set seasonal cycle to be 4 quarters
  insert into esm_sh_settings 
         values(dbms_data_mining.exsm_seasonality,
                '4');
end;
/

-- Build the ESM model
BEGIN
  dbms_data_mining.create_model(model_name => 'ESM_SH_SAMPLE',
               mining_function   => 'TIME_SERIES',
               data_table_name => 'esm_sh_data',
               case_id_column_name => 'time_id',
               target_column_name => 'amount_sold',
               settings_table_name => 'ESM_SH_SETTINGS');
END;
/

-- output setting table
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = upper('ESM_SH_SAMPLE')
ORDER BY setting_name;

-- get signature
column attribute_name format a40
column attribute_type format a20
SELECT attribute_name, attribute_type
FROM   user_mining_model_attributes
  WHERE  model_name=upper('ESM_SH_SAMPLE')
  ORDER BY attribute_name;


-- get global diagnostics
column name format a20
column numeric_value format a20
column string_value format a15
SELECT name, 
to_char(numeric_value, '99999.99EEEE') numeric_value, 
string_value FROM DM$VGESM_SH_SAMPLE
  ORDER BY name;

-- get predictions
set heading on
SET LINES 100
SET PAGES 105
COLUMN CASE_ID FORMAT A30
COLUMN VALUE FORMAT 9999999
COLUMN PREDICTION FORMAT 99999999
COLUMN LOWER FORMAT 99999999
COLUMN UPPER FORMAT 99999999
select case_id, value, prediction, lower, upper 
from DM$VPESM_SH_SAMPLE
ORDER BY case_id;
