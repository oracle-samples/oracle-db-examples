-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   Time Series - Exponential Smoothing Algorithm - dmesmdemo.sql  
--   Copyright (c) 2026 Oracle Corporation and/or its affiliates.
--
--   The Universal Permissive License (UPL), Version 1.0
--   https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

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




-- Create input time series
create or replace view esm_sh_data 
       as SELECT time_id, amount_sold 
FROM sh.sales;


-- Build the ESM model


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('ESM_SH_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst(dbms_data_mining.algo_name) := dbms_data_mining.algo_exponential_smoothing;
  v_setlst(dbms_data_mining.exsm_interval) := dbms_data_mining.exsm_interval_qtr;
  v_setlst(dbms_data_mining.exsm_prediction_step) := '4';
  v_setlst(dbms_data_mining.exsm_model) := dbms_data_mining.exsm_hw;
  v_setlst(dbms_data_mining.exsm_seasonality) := '4';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'ESM_SH_SAMPLE',
    mining_function     => 'TIME_SERIES',
    data_query          => 'SELECT * FROM esm_sh_data',
    case_id_column_name => 'time_id',
    target_column_name  => 'amount_sold',
    set_list            => v_setlst
    );
END;
/
-----------------------------------------------------------------------
-- CREATE_MODEL EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL is useful for application development when model settings
-- are separated into a settings table for convenient updating.
-- This build intentionally replaces the model created by the preceding CREATE_MODEL2 example.

-- Drop settings table if it exists
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ESM_SH_SETTINGS';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('ESM_SH_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE ESM_SH_SETTINGS (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO ESM_SH_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.algo_name, dbms_data_mining.algo_exponential_smoothing);
    INSERT INTO ESM_SH_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.exsm_interval, dbms_data_mining.exsm_interval_qtr);
    INSERT INTO ESM_SH_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.exsm_prediction_step, '4');
    INSERT INTO ESM_SH_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.exsm_model, dbms_data_mining.exsm_hw);
    INSERT INTO ESM_SH_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.exsm_seasonality, '4');
END;
/
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

SELECT case_id, value, PREDICTION, lower, upper 
FROM DM$VPESM_SH_SAMPLE
ORDER BY case_id;


-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('ESM_SH_SAMPLE');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP VIEW ESM_SH_DATA';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE ESM_SH_SETTINGS';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
