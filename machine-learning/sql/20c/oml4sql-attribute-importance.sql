-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   Attribute Importance - "EXPLAIN" function - dmaidemo.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given a target attribute affinity_card, find the importance of
-- attributes that independently impact the target attribute.

-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-------------------
-- Cleanup old output table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ai_explain_output';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- Run the EXPLAIN routine to get attribute importance results
BEGIN
  DBMS_PREDICTIVE_ANALYTICS.EXPLAIN(
    data_table_name     => 'mining_data_build_v',
    explain_column_name => 'affinity_card',
    result_table_name   => 'ai_explain_output');
END;
/

------------------------
-- DISPLAY RESULTS
--
-- List of attribute names ranked by their importance value.
-- The larger the value, the more impact that attribute has
-- on causing variation in the target column.
--
column attribute_name    format a40
column explanatory_value format 9.999
SELECT attribute_name, explanatory_value, rank
FROM ai_explain_output
ORDER BY rank, attribute_name;
