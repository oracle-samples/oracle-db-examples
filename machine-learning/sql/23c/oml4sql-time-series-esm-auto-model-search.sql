-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 23c
--
--   Automated Model Search- Time Series Algorithm ESM
--
--   Copyright (c) 2023 Oracle Corporation and/or its affilitiates.
--
--   The Universal Permissive License (UPL), Version 1.0
--
--   https://oss.oracle.com/licenses/upl
-----------------------------------------------------------------------


-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Create a ESM Time Series Model with Automated Model Search, which is
--   also the default behavior when no ESM model type is specified

-----------------------------------------------------------------------
--                            EXAMPLE IN THIS SCRIPT
-----------------------------------------------------------------------
-- Create an ESM model with CREATE_MODEL2 and Model Search Enabled
-- Evaluate the model 

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-------------------------
-- CREATE VIEW
--

CREATE OR REPLACE VIEW ESM_SH_DATA AS 
SELECT TIME_ID, AMOUNT_SOLD 
FROM   SH.SALES;


-------------------------
-- CREATE MODEL
--

BEGIN DBMS_DATA_MINING.DROP_MODEL('ESM_SALES_FORECAST_1');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
    
    v_setlst('ALGO_NAME')            := 'ALGO_EXPONENTIAL_SMOOTHING';
    v_setlst('EXSM_INTERVAL')        := 'EXSM_INTERVAL_QTR'; 
    v_setlst('EXSM_PREDICTION_STEP') := '4';                  
    v_setlst('EMCS_MODEL_SEARCH')    := 'ENABLE';

    DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'ESM_SALES_FORECAST_1',
        MINING_FUNCTION     => 'TIME_SERIES',
        DATA_QUERY          => 'select * from ESM_SH_DATA',
        SET_LIST            => v_setlst,
        CASE_ID_COLUMN_NAME => 'TIME_ID',
        TARGET_COLUMN_NAME  => 'AMOUNT_SOLD');
END;
/

-----------------------------------------------------------------------
--                            ANALYZE THE MODEL
-----------------------------------------------------------------------
-------------------------
-- GET MODEL DETAILS
--

SELECT setting_name, setting_value, setting_type
FROM   user_mining_model_settings
WHERE  (setting_type != 'DEFAULT' or setting_name like 'EXSM%') 
AND    model_name = upper('ESM_SALES_FORECAST_1')
ORDER BY setting_name;
/


-------------------------
-- COMPUTED SETTINGS AND OTHER GLOBAL STATISTICS
--

SELECT TYPE, name, nval, sval 
FROM   DM$PPESM_SALES_FORECAST_1
ORDER BY TYPE, name;

SELECT global_detail_name, ROUND(global_detail_value,3) global_detail_value
FROM   table(dbms_data_mining.get_model_details_global('ESM_SALES_FORECAST_1'))
ORDER BY global_detail_name;
/

-----------------------------------------------------------------------
--   End of script
-----------------------------------------------------------------------