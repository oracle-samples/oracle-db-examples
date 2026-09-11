-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   OML R Extensible - Association Rules Algorithm - dmrardemo.sql  
--   Copyright (c) 2026 Oracle Corporation and/or its affiliates.
--
--   The Universal Permissive License (UPL), Version 1.0
--   https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 140
SET LONG 10000
SET echo ON


-----------------------------------------------------------------------
--                            SET UP THE DATA
-----------------------------------------------------------------------

-- Cleanup old training data view for repeat runs

BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW ar_build_v';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Create a view for building association rules model
-- The data for this sample is composed from a small subset of
-- sales transactions in the SH schema - listing the (multiple)
-- items bought by a set of customers with ids in the range
-- 100001-104500.
--

CREATE VIEW ar_build_v AS
SELECT cust_id, prod_name, prod_category, amount_sold
FROM (SELECT a.cust_id, b.prod_name, b.prod_category,
             a.amount_sold
FROM sh.sales a, sh.products b
WHERE a.prod_id = b.prod_id AND
             a.cust_id between 100001 AND 104500);


--

-- We will build two separate models for rules and itemsets, respectively.
--

-----------------------------------------------------------------------
--                          BUILD THE MODEL for RULES
-----------------------------------------------------------------------


-------------------
-- SPECIFY SETTINGS
-------------------


BEGIN 
sys.rqScriptDrop('RAR_BUILD');
sys.rqScriptDrop('RAR_DETAILS');
  EXCEPTION WHEN OTHERS THEN NULL; END;
/

------------
-- R scripts
------------

-- The R scripts are created by users using sys.rqScriptCreate to define
-- their own approaches in R for building Association Rules models in 
-- OML4SQL framework.

BEGIN
 
-- The BUILD script will be invoked during CREATE_MODEL
-- Our script here uses the apriori algorithm in R's arules package 
-- to mine rules
  sys.rqScriptCreate('RAR_BUILD', 
    'function(dat){
     library(arules)
     trans <- as(split(dat[["PROD_NAME"]], dat[["CUST_ID"]]), "transactions")
     r <- apriori(trans, parameter = list(minlen=2, supp=0.1, conf=0.5, target="rules"))
     as(r, "data.frame")}');

-- The DETAILS script, along with the FORMAT script below will be 
-- invoked during CREATE_MODEL. A model view will be generated with 
-- the output of the DETAILS script. We deliver the mined rules through
-- the model view                       
  sys.rqScriptCreate('RAR_DETAILS',
     'function(mod) {mod}');
    
END;
/

---------------
-- CREATE MODEL
---------------

-- let case_id_column_name be NULL, as the case_id_column_name should be
-- identified in the R BUILD script


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RAR_SH_AR_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'RAR_BUILD';
  v_setlst(dbms_data_mining.ralg_details_function) := 'RAR_DETAILS';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(100)) rules, 1 support, 1 confidence, 1 lift FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'RAR_SH_AR_SAMPLE',
    mining_function     => dbms_data_mining.association,
    data_query          => 'SELECT * FROM AR_BUILD_V',
    case_id_column_name => NULL,
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
  EXECUTE IMMEDIATE 'DROP TABLE Rar_sh_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RAR_SH_AR_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE Rar_sh_sample_settings (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'RAR_BUILD');
    INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'RAR_DETAILS');
    INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(100)) rules, 1 support, 1 confidence, 1 lift FROM dual');
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'RAR_SH_AR_SAMPLE',
      mining_function     => dbms_data_mining.association,
      data_table_name     => 'AR_BUILD_V',
      case_id_column_name => NULL,
      settings_table_name => 'Rar_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
-------------------------

column setting_name format a30
column setting_value format a40

SELECT setting_name, setting_value FROM Rar_sh_sample_settings
ORDER BY setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
-------------------------

column model_name format a20
column mining_function format a20
column algorithm format a20

SELECT model_name, mining_function, algorithm FROM user_mining_models
WHERE model_name = 'RAR_SH_AR_SAMPLE';

------------------------------------
-- DISPLAY THE RULES USING MODEL VIEW
-- The model view was generated during CREATE_MODEL
--

column partition_name format a5
column rules format A30

SELECT * FROM DM$VDRAR_SH_AR_SAMPLE ORDER BY confidence DESC;


-----------------------------------------------------------------------
--                          BUILD THE MODEL for ITEMSETS
-----------------------------------------------------------------------


-------------------
-- SPECIFY SETTINGS
-------------------



BEGIN
 
-- Our script here uses the apriori algorithm in R's arules package to 
-- mine itemsets
  sys.rqScriptCreate('RAR_BUILD', 
    'function(dat){
     library(arules)
     trans <- as(split(dat[["PROD_NAME"]], dat[["CUST_ID"]]), "transactions")
     items <- apriori(trans, parameter = list(supp=0.1, target="frequent"))
     as(items, "data.frame")}', v_overwrite => TRUE);
            
  sys.rqScriptCreate('RAR_DETAILS',
     'function(mod) {mod}', v_overwrite => TRUE);
    
END;
/


---------------
-- CREATE MODEL
---------------


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RAR_SH_FI_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'RAR_BUILD';
  v_setlst(dbms_data_mining.ralg_details_function) := 'RAR_DETAILS';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(100)) items, 1 support FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'RAR_SH_FI_SAMPLE',
    mining_function     => dbms_data_mining.association,
    data_query          => 'SELECT * FROM AR_BUILD_V',
    case_id_column_name => NULL,
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
  EXECUTE IMMEDIATE 'DROP TABLE Rar_sh_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RAR_SH_FI_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE Rar_sh_sample_settings (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'RAR_BUILD');
    INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'RAR_DETAILS');
    INSERT INTO Rar_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(100)) items, 1 support FROM dual');
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'RAR_SH_FI_SAMPLE',
      mining_function     => dbms_data_mining.association,
      data_table_name     => 'AR_BUILD_V',
      case_id_column_name => NULL,
      settings_table_name => 'Rar_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
-------------------------

column setting_name format a30
column setting_value format a40

SELECT setting_name, setting_value FROM Rar_sh_sample_settings
ORDER BY setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
-------------------------

column model_name format a20
column mining_function format a20
column algorithm format a20

SELECT model_name, mining_function, algorithm FROM user_mining_models
WHERE model_name = 'RAR_SH_FI_SAMPLE';

---------------------------------------
-- DISPLAY THE ITEMSETS USING MODEL VIEW
---------------------------------------

column partition_name format a5
column items format a50

SELECT * FROM DM$VDRAR_SH_FI_SAMPLE ORDER BY support DESC;


-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('RAR_SH_AR_SAMPLE');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('RAR_SH_FI_SAMPLE');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP VIEW AR_BUILD_V';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE RAR_SH_SAMPLE_SETTINGS';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
