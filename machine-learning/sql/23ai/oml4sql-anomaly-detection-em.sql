-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 23ai
--
--   Expectation Maximization - EM Algorithm for Anomaly Detection
--
--   Copyright (c) 2024 Oracle Corporation and/or its affilitiates.
--
--   The Universal Permissive License (UPL), Version 1.0
--
--   https://oss.oracle.com/licenses/upl
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
-- Segment the demographic data into clusters and examine the anomalies.

-----------------------------------------------------------------------
--                            EXAMPLE IN THIS SCRIPT
-----------------------------------------------------------------------
-- Create EM model with CREATE MODEL2 
-- View model details 
-- View and sort anomalous customers 
-- View prediction details

-----------------------------------------------------------------------
-- In this script, we are using an EM classification model to expand on 
-- the One-Class SVM model approach for anomaly detection. EM 
-- can capture the underlying data distribution and thus flag records 
-- that do not fit the learned data distribution well. An object is 
-- identified as an outlier in an EM Anomaly Detection model if its anomaly 
-- probability is greater than 0.5. A label of 1 denotes normal, while 
-- a label of 0 denotes anomaly. The customer and demographics data is 
-- used to predict anomalous customers using prob_anomalous.

-----------------------------------------------------------------------
--                  SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

------------------------------
-- CREATE VIEW DEMOGRAPHICS_V
--
CREATE OR REPLACE VIEW DEMOGRAPHICS_V AS
  SELECT CUST_ID, YRS_RESIDENCE, EDUCATION, AFFINITY_CARD, 
         HOUSEHOLD_SIZE, OCCUPATION, BOOKKEEPING_APPLICATION, 
         BULK_PACK_DISKETTES, FLAT_PANEL_MONITOR, HOME_THEATER_PACKAGE,
         OS_DOC_SET_KANJI, PRINTER_SUPPLIES, Y_BOX_GAMES
  FROM SH.SUPPLEMENTARY_DEMOGRAPHICS;

-------------------------
-- CREATE VIEW JOINING CUSTOMERS AND DEMOGRAPHICS_V
--

CREATE OR REPLACE VIEW CUSTOMERS360_V AS
   SELECT a.CUST_ID, a.CUST_GENDER, a.CUST_MARITAL_STATUS, a.CUST_YEAR_OF_BIRTH, 
          a.CUST_INCOME_LEVEL, a.CUST_CREDIT_LIMIT, b.EDUCATION, b.AFFINITY_CARD, 
          b.HOUSEHOLD_SIZE, b.OCCUPATION, b.YRS_RESIDENCE, b.Y_BOX_GAMES
   FROM SH.CUSTOMERS a, DEMOGRAPHICS_V b
   WHERE a.CUST_ID = b.CUST_ID;

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-------------------------
-- SET OUTLIER RATE IN SETTINGS TABLE - DEFAULT IS 0.05
--

BEGIN DBMS_DATA_MINING.DROP_MODEL('CUSTOMERS360MODEL_AD');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_NAME')         := 'ALGO_EXPECTATION_MAXIMIZATION';
  v_setlst('PREP_AUTO')         := 'ON';
  v_setlst('EMCS_OUTLIER_RATE') := '0.1';
        
  DBMS_DATA_MINING.CREATE_MODEL2(
        MODEL_NAME          => 'CUSTOMERS360MODEL_AD',
        MINING_FUNCTION     => 'CLASSIFICATION',
        DATA_QUERY          => 'SELECT * FROM CUSTOMERS360_V',
        CASE_ID_COLUMN_NAME => 'CUST_ID',
        SET_LIST            => v_setlst,
        TARGET_COLUMN_NAME  => NULL); -- NULL target indicates anomaly detection      
END;
/

-----------------------------------------------------------------------
--                   EXAMINE THE MODEL
-----------------------------------------------------------------------
-------------------------
-- DISPLAY MODEL DETAILS
--

SELECT * 
FROM  TABLE(dbms_data_mining.get_model_details_global('CUSTOMERS360MODEL_AD'))
ORDER BY global_detail_name;

---------------------------------------------
-- DISPLAY THE TOP 5 MOST ANOMALOUS CUSTOMERS
--

SELECT * 
FROM (SELECT CUST_ID, round(prob_anomalous,2) prob_anomalous,  
             YRS_RESIDENCE, CUST_MARITAL_STATUS, 
             rank() over (ORDER BY prob_anomalous DESC) rnk 
      FROM (SELECT CUST_ID, HOUSEHOLD_SIZE, YRS_RESIDENCE, CUST_GENDER, CUST_MARITAL_STATUS, 
                   prediction_probability(CUSTOMERS360MODEL, '0' USING *) prob_anomalous
            FROM CUSTOMERS360_V))
WHERE rnk <= 5
ORDER BY prob_anomalous DESC;
---------------------------------------------------------------
-- CREATE VIEW OF CUSTOMERS IN DESCENDING ORDER OF ANOMALY PROBABILITY
--
CREATE OR REPLACE VIEW EM_ANOMALOUS_RESULTS AS
SELECT * 
FROM (SELECT CUST_ID, anomalous, round(prob_anomalous,2) prob_anomalous, 
             YRS_RESIDENCE, HOUSEHOLD_SIZE, CUST_GENDER,
             CUST_MARITAL_STATUS, 
             RANK() OVER (ORDER BY prob_anomalous DESC) rnk 
      FROM (SELECT CUST_ID, HOUSEHOLD_SIZE, YRS_RESIDENCE, 
                   CUST_GENDER, CUST_MARITAL_STATUS, 
                   prediction(CUSTOMERS360MODEL_AD using *) anomalous,
                   prediction_probability(CUSTOMERS360MODEL_AD, '0' USING *) prob_anomalous
            FROM CUSTOMERS360_V))
ORDER BY prob_anomalous DESC;

SELECT * 
FROM   EM_ANOMALOUS_RESULTS
FETCH FIRST 10 ROWS ONLY;

--------------------------------------------------------------------
-- VIEW PREDICTION DETAILS OF TOP 3 ATTRIBUTES TO EXPLAIN PREDICTION
--

SELECT CUST_ID, PREDICTION,
       RTRIM(TRIM(SUBSTR(OUTPRED."Attribute1",17,100)),'rank="1"/>') FIRST_ATTRIBUTE,
       RTRIM(TRIM(SUBSTR(OUTPRED."Attribute2",17,100)),'rank="2"/>') SECOND_ATTRIBUTE,
       RTRIM(TRIM(SUBSTR(OUTPRED."Attribute3",17,100)),'rank="3"/>') THIRD_ATTRIBUTE
FROM (SELECT CUST_ID, 
             PREDICTION(CUSTOMERS360MODEL USING *) PREDICTION,
             PREDICTION_DETAILS(CUSTOMERS360MODEL, '0' USING *) PREDICTION_DETAILS 
      FROM   CUSTOMERS360_V
      WHERE  PREDICTION_PROBABILITY(CUSTOMERS360MODEL, '0' USING *) > 0.50
      AND OCCUPATION = 'TechSup'
      ORDER BY CUST_ID) OUT,
      XMLTABLE('/Details'
                PASSING OUT.PREDICTION_DETAILS
                COLUMNS 
                   "Attribute1" XMLType PATH 'Attribute[1]',
                   "Attribute2" XMLType PATH 'Attribute[2]',
                   "Attribute3" XMLType PATH 'Attribute[3]') OUTPRED
FETCH FIRST 10 ROWS ONLY;


-----------------------------------------------------------------------
--   End of script
-----------------------------------------------------------------------