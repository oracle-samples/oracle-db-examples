-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   OML R Extensible - Association Rules Algorithm - dmrardemo.sql
--   
--   Copyright (c) 2025 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------
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
BEGIN EXECUTE IMMEDIATE 'DROP VIEW ar_build_v';
EXCEPTION WHEN OTHERS THEN NULL; END;
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

-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('RAR_SH_AR_SAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table and R scripts for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Rar_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN 
sys.rqScriptDrop('RAR_BUILD');
sys.rqScriptDrop('RAR_DETAILS');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE Rar_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

------------
-- R scripts
--
-- The R scripts are created by users using sys.rqScriptCreate to define
-- their own approaches in R for building Association Rules models in 
-- ODM framework.

BEGIN
  INSERT INTO Rar_sh_sample_settings VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
 
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
    
  INSERT INTO Rar_sh_sample_settings VALUES
  (dbms_data_mining.ralg_build_function, 'RAR_BUILD');
  INSERT INTO Rar_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_function, 'RAR_DETAILS');
  INSERT INTO Rar_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_format, 
  'select cast(''a'' as varchar2(100)) rules, 1 support, 1 confidence, 1 lift from dual');
END;
/

---------------
-- CREATE MODEL
--
-- let case_id_column_name be NULL, as the case_id_column_name should be
-- identified in the R BUILD script
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
--
column setting_name format a30
column setting_value format a40
select setting_name, setting_value from Rar_sh_sample_settings
order by setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
--
column model_name format a20
column mining_function format a20
column algorithm format a20
select model_name, mining_function, algorithm from user_mining_models
where model_name = 'RAR_SH_AR_SAMPLE';

------------------------------------
-- DISPLAY THE RULES USING MODEL VIEW
-- The model view was generated during CREATE_MODEL
--
column partition_name format a5
column rules format A30
select * from DM$VDRAR_SH_AR_SAMPLE order by confidence desc;



-----------------------------------------------------------------------
--                          BUILD THE MODEL for ITEMSETS
-----------------------------------------------------------------------

-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('RAR_SH_FI_SAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Rar_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/


CREATE TABLE Rar_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

BEGIN
  INSERT INTO Rar_sh_sample_settings VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
 
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
    
  INSERT INTO Rar_sh_sample_settings VALUES
  (dbms_data_mining.ralg_build_function, 'RAR_BUILD');
  INSERT INTO Rar_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_function, 'RAR_DETAILS');
  INSERT INTO Rar_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_format, 
  'select cast(''a'' as varchar2(100)) items, 1 support from dual');
END;
/


---------------
-- CREATE MODEL
--
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
--
column setting_name format a30
column setting_value format a40
select setting_name, setting_value from Rar_sh_sample_settings
order by setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
--
column model_name format a20
column mining_function format a20
column algorithm format a20
select model_name, mining_function, algorithm from user_mining_models
where model_name = 'RAR_SH_FI_SAMPLE';

---------------------------------------
-- DISPLAY THE ITEMSETS USING MODEL VIEW
--
column partition_name format a5
column items format a50
select * from DM$VDRAR_SH_FI_SAMPLE order by support desc;

