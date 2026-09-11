-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   OML R Extensible - Attribute Importance via RF Algorithm - dmraidemo.sql  
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

-------------------------------------------------------------------------------
--                         ATTRIBUTE IMPORTANCE DEMO
-------------------------------------------------------------------------------

-- Explaination:
-- This demo shows how to implement the attribute importance algorithm in 
-- Oracle Data Mining using R randomForest algorithm

-- Cleanup old output tables/scripts/models for repeat runs -------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE AI_RDEMO_SETTINGS';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  sys.rqScriptDrop('AI_RDEMO_BUILD_FUNCTION', v_silent => TRUE);
  sys.rqScriptDrop('AI_RDEMO_DETAILS_FUNCTION', v_silent => TRUE);
END;
/


-- Create setting table -------------------------------------------------------


BEGIN
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named AI_RDEMO_BUILD_FUNCTION is defined. This 
-- function builds and returns a random forest model using R randomForest 
-- algorithm. User can also choose other R algorithm to get the attribute 
-- importance.

  sys.rqScriptCreate('AI_RDEMO_BUILD_FUNCTION', 'function(dat) {
    require(randomForest); 
    set.seed(1234);
    mod <- randomForest(AFFINITY_CARD ~ ., data=dat);
    mod}');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named AI_RDEMO_DETAILS_FUNCTION 
-- is defined. This function creates and returns an R data.frame containing the 
-- attribute importance of the built model. User can also display other details.

  sys.rqScriptCreate('AI_RDEMO_DETAILS_FUNCTION', 'function(object, x)
   {require(randomForest); 
   mod <- object;
   data.frame(row_name=row.names(mod$importance), importance=mod$importance)}');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding importance.

END;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------

-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- AI_RDEMO_BUILD_FUNCTION will be used to create the model AI_RDEMO, using 
-- dataset mining_data_build_v.


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('AI_RDEMO');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'AI_RDEMO_BUILD_FUNCTION';
  v_setlst(dbms_data_mining.ralg_details_function) := 'AI_RDEMO_DETAILS_FUNCTION';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(100)) name, 1 importance FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'AI_RDEMO',
    mining_function     => dbms_data_mining.regression,
    data_query          => 'SELECT * FROM mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'AFFINITY_CARD',
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
  EXECUTE IMMEDIATE 'DROP TABLE AI_RDEMO_SETTINGS';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('AI_RDEMO');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE AI_RDEMO_SETTINGS (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO AI_RDEMO_SETTINGS (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO AI_RDEMO_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'AI_RDEMO_BUILD_FUNCTION');
    INSERT INTO AI_RDEMO_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'AI_RDEMO_DETAILS_FUNCTION');
    INSERT INTO AI_RDEMO_SETTINGS (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(100)) name, 1 importance FROM dual');
END;
/
BEGIN
  dbms_data_mining.create_model(
      model_name          => 'AI_RDEMO',
      mining_function     => dbms_data_mining.regression,
      data_table_name     => 'mining_data_build_v',
      case_id_column_name => 'CUST_ID',
      target_column_name  => 'AFFINITY_CARD',
      settings_table_name => 'AI_RDEMO_SETTINGS');
END;
/

-------------------------------------------------------------------------------
--                           ATTRIBUTE IMPORTANCE
-------------------------------------------------------------------------------

-- Attribute Importance
-- Explanation:
-- Display the model details using the R script user defined. Here R script 
-- AI_RDEMO_DETAIL_FUNCTION will be used to provide the attribute importance.

column name format a30;

SELECT name, round(importance, 3) as importance, 
rank() OVER (ORDER BY importance DESC) rank 
FROM DM$VDAI_RDEMO ORDER BY importance DESC, name;

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('AI_RDEMO');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE AI_RDEMO_SETTINGS';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
