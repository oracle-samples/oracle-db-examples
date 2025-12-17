-----------------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--
--   Survival Analysis Modeling using XGBoost
--  
--   Copyright (c) 2025 Oracle Corporation and/or its affiliates.
--   The Universal Permissive License (UPL), Version 1.0
--
--   https://oss.oracle.com/licenses/upl/

-----------------------------------------------------------------------------
-- For more information...

-- Oracle ADW Documentation: 
-- https://docs.oracle.com/en/cloud/paas/autonomous-data-warehouse-cloud/index.html

-- OML Folder on Github: 
-- https://github.com/oracle/oracle-db-examples/tree/master/machine-learning

-- OML Web Page: 
-- https://www.oracle.com/machine-learning

-- OML Regression:
-- https://www.oracle.com/goto/ml-regression

-- OML XGBoost: 
-- https://http://www.oracle.com/goto/ml-xgboost
 
-----------------------------------------------------------------------------
--                   EXAMPLES IN THIS SCRIPT
-----------------------------------------------------------------------------
-- Create a Survival Analysis XGBoost Model using CREATE_MODEL2
-- Walk through XGB algorithm settings with the model
-- Survival analysis with AFT model

-----------------------------------------------------------------------------
--         Examples of Setting Overrides for XGBoost 
-----------------------------------------------------------------------------

-- If the user does not override the default settings, relevant settings 
-- are determined by the algorithm. 

-- A complete list of settings can be found in the documentation link:
-- https://docs.oracle.com/en/database/oracle/oracle-database/21/arpls/
-- DBMS_DATA_MINING.html#GUID-443B3D58-8B74-422E-8E51-C8F609249B2C

-- Set evaluation metric:
--   v_setlst('eval_metric') := 'cox-nloglik';
--   v_setlst('eval_metric') := 'aft-nloglik';
--   v_setlst('eval_metric') := 'c-index';
--   v_setlst('eval_metric') := 'ndcg';

-- Regularization parameters for all boosters:
--   v_setlst('alpha')  := '0.1';
--   v_setlst('eta')    := '0.3';
--   v_setlst('lambda') := '0.3';

-- Subsampling methods:
--   v_setlst('max_depth')         := '6';
--   v_setlst('min_child_weight')  := '1';
--   v_setlst('colsample_bytree')  := '0.9';

-- Set a tree method:
--   v_setlst('tree_method')  := 'hist';
--   v_setlst('tree_method')  := 'exact';
--   v_setlst('tree_method')  := 'approx';
--   v_setlst('tree_method')  := 'gpu_exact';
--   v_setlst('tree_method')  := 'gpu_hist';

-- Number of iteration rounds:
--   v_setlst('num_round') := '100';

-- For XGBoost survival tasks, the objective is:
--   v_setlst('objective') := 'survival:aft';
--   v_setlst('objective') := 'survival:cox';
--   v_setlst('objective') := 'survival:cox-nloglik';
--   v_setlst('objective') := 'survival:cox-gamma';

-- Specify loss distribution:
--   v_setlst('aft_loss_distribution') := 'normal';
--   v_setlst('aft_loss_distribution') := 'logistic';
--   v_setlst('aft_loss_distribution') := 'extreme';

-----------------------------------------------------------------------------
--         Create a data table with left and right bound columns
-----------------------------------------------------------------------------

-- The data table 'SURVIVAL_DATA' contains both exact data point and 
-- right-censored data point. The left bound column is set by 
-- parameter target_column_name. The right bound column is set 
-- by setting aft_right_bound_column_name.

-- For right censored data point, the right bound is infinity,
-- which is represented as NULL in the right bound column.

BEGIN EXECUTE IMMEDIATE 'DROP TABLE SURVIVAL_DATA';
EXCEPTION WHEN OTHERS THEN NULL; END;
/ 
CREATE TABLE SURVIVAL_DATA (INST NUMBER, LBOUND NUMBER, AGE NUMBER, 
                            SEX NUMBER, PHECOG NUMBER, PHKARNO NUMBER, 
                            PATKARNO NUMBER, MEALCAL NUMBER, WTLOSS NUMBER, 
                            RBOUND NUMBER);                
INSERT INTO SURVIVAL_DATA VALUES(26, 235, 63, 2, 0, 100,  90,  413,  0,   NULL);
INSERT INTO SURVIVAL_DATA VALUES(22, 444, 75, 2, 2,  70,  70,  438,  8,   444);
INSERT INTO SURVIVAL_DATA VALUES(16, 806, 44, 1, 1,  80,  80, 1025,  1,   NULL);
INSERT INTO SURVIVAL_DATA VALUES(16, 551, 77, 2, 2,  80,  60,  750, 28,   NULL);
INSERT INTO SURVIVAL_DATA VALUES(3,  202, 50, 2, 0, 100, 100,  635,  1,   NULL);
INSERT INTO SURVIVAL_DATA VALUES(7,  583, 68, 1, 1,  60,  70, 1025,  7,   583);
INSERT INTO SURVIVAL_DATA VALUES(32, 135, 60, 1, 1,  90,  70, 1275,  0,   135);
INSERT INTO SURVIVAL_DATA VALUES(21, 237, 69, 1, 1,  80,  70, NULL, NULL, NULL);
INSERT INTO SURVIVAL_DATA VALUES(26, 356, 53, 2, 1,  90,  90, NULL,   2,  NULL);
INSERT INTO SURVIVAL_DATA VALUES(13, 387, 56, 1, 2,  80,  60, 1075, NULL, 387);

-----------------------------------------------------------------------------
--             Build an XGBoost survival model with survival:aft
-----------------------------------------------------------------------------

BEGIN DBMS_DATA_MINING.DROP_MODEL('XGB_SURVIVAL_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
    v_setlst('ALGO_NAME')                    := 'ALGO_XGBOOST';
    v_setlst('max_depth')                    := '6';
    v_setlst('eval_metric')                  := 'aft-nloglik';
    v_setlst('num_round')                    := '100';
    v_setlst('objective')                    := 'survival:aft';
    v_setlst('aft_right_bound_column_name')  := 'rbound';
    v_setlst('aft_loss_distribution')        := 'normal';
    v_setlst('aft_loss_distribution_scale')  := '1.20';
    v_setlst('eta')                          := '0.05';
    v_setlst('lambda')                       := '0.01';
    v_setlst('alpha')                        := '0.02';
    v_setlst('tree_method')                  := 'hist';

    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'XGB_SURVIVAL_MODEL',
        MINING_FUNCTION     => 'REGRESSION',
        DATA_QUERY          => 'SELECT * FROM SURVIVAL_DATA',
        TARGET_COLUMN_NAME  => 'LBOUND',
        CASE_ID_COLUMN_NAME =>  NULL,
        SET_LIST            =>  v_setlst);
END;
/

-----------------------------------------------------------------------------
--                    Get Prediction Details 
-----------------------------------------------------------------------------
--  NULL value in rbound (aft_right_bound_column_name) column 
--    is intepreted as infinity.

COLUMN PRED FORMAT 99999
SET LONG 20000
SET LINES 100

SELECT LBOUND, RBOUND, 
       ROUND(PREDICTION(XGB_SURVIVAL_MODEL  USING *),3) PRED 
FROM   SURVIVAL_DATA;

-----------------------------------------------------------------------------
--              Nest data into numerical values
-----------------------------------------------------------------------------

CREATE OR REPLACE VIEW SURVIVAL_NUMERIC AS 
SELECT LBOUND, RBOUND, WTLOSS,
       DM_NESTED_NUMERICALS(
         DM_NESTED_NUMERICAL('INST', INST),
         DM_NESTED_NUMERICAL('AGE', AGE),
         DM_NESTED_NUMERICAL('SEX', SEX),
         DM_NESTED_NUMERICAL('PHECOG', PHECOG),
         DM_NESTED_NUMERICAL('PHKARNO', PHKARNO),
         DM_NESTED_NUMERICAL('PATKARNO', PATKARNO),
         DM_NESTED_NUMERICAL('MEALCAL', MEALCAL)) NNUM 
FROM  SURVIVAL_DATA;

-----------------------------------------------------------------------------
-- Build an XGBoost model using nested numeric data
-----------------------------------------------------------------------------

BEGIN DBMS_DATA_MINING.DROP_MODEL('XGB_SURVIVAL_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
    v_setlst('ALGO_NAME')                    := 'ALGO_XGBOOST';
    v_setlst('max_depth')                    := '6';
    v_setlst('eval_metric')                  := 'aft-nloglik';
    v_setlst('num_round')                    := '100';
    v_setlst('objective')                    := 'survival:aft';
    v_setlst('aft_right_bound_column_name')  := 'rbound';
    v_setlst('aft_loss_distribution')        := 'normal';
    v_setlst('aft_loss_distribution_scale')  := '1.20';
    v_setlst('eta')                          := '0.05';
    v_setlst('lambda')                       := '0.01';
    v_setlst('alpha')                        := '0.02';
    v_setlst('tree_method')                  := 'hist';

    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'XGB_SURVIVAL_MODEL',
        MINING_FUNCTION     => 'REGRESSION',
        DATA_QUERY          => 'SELECT * FROM SURVIVAL_NUMERIC',
        TARGET_COLUMN_NAME  => 'LBOUND',
        CASE_ID_COLUMN_NAME =>  NULL,
        SET_LIST            =>  v_setlst);
END;
/

-----------------------------------------------------------------------------
--                    Get Prediction Details 
-----------------------------------------------------------------------------
-- NULL value in rbound (aft_right_bound_column_name) column
--   is intepreted as infinity.

COLUMN PRED FORMAT 99999
SET LONG 20000
SET LINES 100

SELECT LBOUND, RBOUND, 
       ROUND(PREDICTION(XGB_SURVIVAL_MODEL  USING *),3) PRED 
FROM   SURVIVAL_NUMERIC;

-----------------------------------------------------------------------------
--    Build an XGBoost model with no eval_metric specified
-----------------------------------------------------------------------------

BEGIN DBMS_DATA_MINING.DROP_MODEL('XGB_SURVIVAL_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
begin
    v_setlst('ALGO_NAME')                    := 'ALGO_XGBOOST';
    v_setlst('max_depth')                    := '6';
    v_setlst('num_round')                    := '100';
    v_setlst('objective')                    := 'survival:aft';
    v_setlst('aft_right_bound_column_name')  := 'rbound';
    v_setlst('aft_loss_distribution')        := 'normal';
    v_setlst('aft_loss_distribution_scale')  := '1.20';
    v_setlst('eta')                          := '0.05';
    v_setlst('lambda')                       := '0.01';
    v_setlst('alpha')                        := '0.02';
    v_setlst('tree_method')                  := 'hist';

    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'XGB_SURVIVAL_MODEL',
        MINING_FUNCTION     => 'REGRESSION',
        DATA_QUERY          => 'SELECT * FROM SURVIVAL_DATA',
        TARGET_COLUMN_NAME  => 'LBOUND',
        CASE_ID_COLUMN_NAME =>  NULL,
        SET_LIST            =>  v_setlst);
END;
/

-----------------------------------------------------------------------------
--                    Get Prediction Details 
-----------------------------------------------------------------------------

SELECT LBOUND, RBOUND, 
       ROUND(PREDICTION(XGB_SURVIVAL_MODEL  USING *),3) PRED 
FROM   SURVIVAL_DATA;

-----------------------------------------------------------------------------
--    Build an XGBoost model with aft_loss_distribution = logistic
-----------------------------------------------------------------------------

BEGIN DBMS_DATA_MINING.DROP_MODEL('XGB_SURVIVAL_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
    v_setlst('ALGO_NAME')                    := 'ALGO_XGBOOST';
    v_setlst('max_depth')                    := '6';
    v_setlst('eval_metric')                  := 'aft-nloglik';
    v_setlst('num_round')                    := '100';
    v_setlst('objective')                    := 'survival:aft';
    v_setlst('aft_right_bound_column_name')  := 'rbound';
    v_setlst('aft_loss_distribution')        := 'logistic';
    v_setlst('aft_loss_distribution_scale')  := '1.20';
    v_setlst('eta')                          := '0.05';
    v_setlst('lambda')                       := '0.01';
    v_setlst('alpha')                        := '0.02';
    v_setlst('tree_method')                  := 'hist';

    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'XGB_SURVIVAL_MODEL',
        MINING_FUNCTION     => 'REGRESSION',
        DATA_QUERY          => 'SELECT * FROM SURVIVAL_DATA',
        TARGET_COLUMN_NAME  => 'LBOUND',
        CASE_ID_COLUMN_NAME =>  NULL,
        SET_LIST            =>  v_setlst);
END;
/

-----------------------------------------------------------------------------
--                    Get Prediction Details 
-----------------------------------------------------------------------------

SELECT LBOUND, RBOUND, 
       ROUND(PREDICTION(XGB_SURVIVAL_MODEL USING *),3) PRED 
FROM   SURVIVAL_DATA;

-----------------------------------------------------------------------------
--    Build an XGBoost model with aft_loss_distribution = extreme
-----------------------------------------------------------------------------

BEGIN DBMS_DATA_MINING.DROP_MODEL('XGB_SURVIVAL_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
    v_setlst('ALGO_NAME')                    := 'ALGO_XGBOOST';
    v_setlst('max_depth')                    := '6';
    v_setlst('eval_metric')                  := 'aft-nloglik';
    v_setlst('num_round')                    := '100';
    v_setlst('objective')                    := 'survival:aft';
    v_setlst('aft_right_bound_column_name')  := 'rbound';
    v_setlst('aft_loss_distribution')        := 'extreme';
    v_setlst('aft_loss_distribution_scale')  := '1.20';
    v_setlst('eta')                          := '0.05';
    v_setlst('lambda')                       := '0.01';
    v_setlst('alpha')                        := '0.02';
    v_setlst('tree_method')                  := 'hist';

    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'XGB_SURVIVAL_MODEL',
        MINING_FUNCTION     => 'REGRESSION',
        DATA_QUERY          => 'SELECT * FROM SURVIVAL_DATA',
        TARGET_COLUMN_NAME  => 'LBOUND',
        CASE_ID_COLUMN_NAME =>  NULL,
        SET_LIST            =>  v_setlst);
END;
/

-----------------------------------------------------------------------------
--                    Get Prediction Details 
-----------------------------------------------------------------------------

SELECT LBOUND, RBOUND, 
       ROUND(PREDICTION(XGB_SURVIVAL_MODEL  USING *),3) PRED 
FROM   SURVIVAL_DATA;

-----------------------------------------------------------------------------
--    Build an XGBoost model with aft_loss_distribution_scale = 0 
-----------------------------------------------------------------------------

BEGIN DBMS_DATA_MINING.DROP_MODEL('XGB_SURVIVAL_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
    v_setlst('ALGO_NAME')                    := 'ALGO_XGBOOST';
    v_setlst('max_depth')                    := '6';
    v_setlst('eval_metric')                  := 'aft-nloglik';
    v_setlst('num_round')                    := '100';
    v_setlst('objective')                    := 'survival:aft';
    v_setlst('aft_right_bound_column_name')  := 'rbound';
    v_setlst('aft_loss_distribution')        := 'extreme';
    v_setlst('aft_loss_distribution_scale')  := '0';
    v_setlst('eta')                          := '0.05';
    v_setlst('lambda')                       := '0.01';
    v_setlst('alpha')                        := '0.02';
    v_setlst('tree_method')                  := 'hist';
    
    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'XGB_SURVIVAL_MODEL',
        MINING_FUNCTION     => 'REGRESSION',
        DATA_QUERY          => 'SELECT * FROM SURVIVAL_DATA',
        TARGET_COLUMN_NAME  => 'LBOUND',
        CASE_ID_COLUMN_NAME =>  NULL,
        SET_LIST            =>  v_setlst);
END;
/

-----------------------------------------------------------------------------
--                    Get Prediction Details 
-----------------------------------------------------------------------------

SELECT LBOUND, RBOUND, 
       ROUND(PREDICTION(XGB_SURVIVAL_MODEL  USING *),3) PRED 
From   SURVIVAL_DATA;

-----------------------------------------------------------------------------
--          Create a table with only one numerical column
-----------------------------------------------------------------------------

DROP TABLE SURVIVAL_DATA;
CREATE TABLE SURVIVAL_DATA (LBOUND NUMBER, RBOUND NUMBER);                
INSERT INTO SURVIVAL_DATA VALUES(235, NULL);
INSERT INTO SURVIVAL_DATA VALUES(444, 444);
INSERT INTO SURVIVAL_DATA VALUES(806, NULL);
INSERT INTO SURVIVAL_DATA VALUES(551, NULL);
INSERT INTO SURVIVAL_DATA VALUES(202, NULL);
INSERT INTO SURVIVAL_DATA VALUES(583, 583);
INSERT INTO SURVIVAL_DATA VALUES(135, 135);
INSERT INTO SURVIVAL_DATA VALUES(237, NULL);
INSERT INTO SURVIVAL_DATA VALUES(356, NULL);
INSERT INTO SURVIVAL_DATA VALUES(387, 387);

-----------------------------------------------------------------------------
--        Build an XGBoost model using numerical table  
-----------------------------------------------------------------------------

BEGIN DBMS_DATA_MINING.DROP_MODEL('XGB_SURVIVAL_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
    v_setlst('ALGO_NAME')                    := 'ALGO_XGBOOST';
    v_setlst('max_depth')                    := '6';
    v_setlst('eval_metric')                  := 'aft-nloglik';
    v_setlst('num_round')                    := '100';
    v_setlst('objective')                    := 'survival:aft';
    v_setlst('aft_right_bound_column_name')  := 'rbound';
    v_setlst('aft_loss_distribution')        := 'normal';
    v_setlst('aft_loss_distribution_scale')  := '1.20';
    v_setlst('eta')                          := '0.05';
    v_setlst('lambda')                       := '0.01';
    v_setlst('alpha')                        := '0.02';
    v_setlst('tree_method')                  := 'hist';

    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'XGB_SURVIVAL_MODEL',
        MINING_FUNCTION     => 'REGRESSION',
        DATA_QUERY          => 'SELECT * FROM SURVIVAL_DATA',
        TARGET_COLUMN_NAME  => 'LBOUND',
        CASE_ID_COLUMN_NAME =>  NULL,
        SET_LIST            =>  v_setlst);
END;
/

-----------------------------------------------------------------------------
--                    Get Prediction Details 
-----------------------------------------------------------------------------

SELECT LBOUND, RBOUND, 
       ROUND(PREDICTION(XGB_SURVIVAL_MODEL  USING *),3) PRED 
FROM   SURVIVAL_DATA;

-----------------------------------------------------------------------
--   End of script
-----------------------------------------------------------------------