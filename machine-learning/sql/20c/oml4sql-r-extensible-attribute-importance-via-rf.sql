-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   OML R Extensible - Attribute Importance via RF Algorithm - dmraidemo.sql
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

-------------------------------------------------------------------------------
--                         ATTRIBUTE IMPORTANCE DEMO
-------------------------------------------------------------------------------
-- Explaination:
-- This demo shows how to implement the attribute importance algorithm in 
-- Oracle Data Mining using R randomForest algorithm

-- Cleanup old output tables/scripts/models for repeat runs -------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AI_RDEMO_SETTINGS';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
  sys.rqScriptDrop('AI_RDEMO_BUILD_FUNCTION', v_silent => TRUE);
  sys.rqScriptDrop('AI_RDEMO_DETAILS_FUNCTION', v_silent => TRUE);
END;
/

BEGIN DBMS_DATA_MINING.DROP_MODEL('AI_RDEMO');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create setting table -------------------------------------------------------
create table AI_RDEMO_SETTINGS(
        setting_name varchar2(30),
        setting_value varchar2(4000));

BEGIN
 INSERT INTO AI_RDEMO_SETTINGS VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
END;
/

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

   INSERT INTO AI_RDEMO_SETTINGS 
     VALUES(dbms_data_mining.ralg_build_function, 'AI_RDEMO_BUILD_FUNCTION');
   INSERT INTO AI_RDEMO_SETTINGS 
     VALUES(dbms_data_mining.ralg_details_function, 'AI_RDEMO_DETAILS_FUNCTION');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding importance.

   INSERT INTO AI_RDEMO_SETTINGS 
     VALUES(dbms_data_mining.ralg_details_format, 
     'select cast(''a'' as varchar2(100)) name, 1 importance from dual');
END;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------
-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- AI_RDEMO_BUILD_FUNCTION will be used to create the model AI_RDEMO, using 
-- dataset mining_data_build_v.

begin
  dbms_data_mining.create_model(
    model_name          => 'AI_RDEMO',
    mining_function     => dbms_data_mining.regression,
    data_table_name     => 'mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'AFFINITY_CARD',
    settings_table_name => 'AI_RDEMO_SETTINGS');
end;
/

-------------------------------------------------------------------------------
--                           ATTRIBUTE IMPORTANCE
-------------------------------------------------------------------------------

-- Attribute Importance
-- Explanation:
-- Display the model details using the R script user defined. Here R script 
-- AI_RDEMO_DETAIL_FUNCTION will be used to provide the attribute importance.

column name format a30;
select name, round(importance, 3) as importance, 
rank() OVER (ORDER BY importance DESC) rank 
from DM$VDAI_RDEMO order by importance desc, name;
