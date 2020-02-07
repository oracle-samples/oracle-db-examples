Rem
Rem $Header: rdbms/demo/dmaidemo.sql /main/5 2012/04/15 16:31:57 xbarr Exp $
Rem
Rem dmaidemo.sql
Rem
Rem Copyright (c) 2003, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      dmaidemo.sql - Sample program for the DBMS_PREDICTIVE_ANALYTICS package.
Rem
Rem    DESCRIPTION
Rem      This script runs the predictive analytics EXPLAIN routine
Rem      to understand the factors which cause variation in a target column.
Rem      The explain routine uses an Attribute Importance model
Rem      (leveraging the MDL algorithm).
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    amozes      01/26/12 - updates for 12c
Rem    ktaylor     07/11/05 - minor edits to comments
Rem    jcjeon      01/18/05 - add column format 
Rem    ramkrish    10/26/04 - add data analysis and comments/cleanup 
Rem    ramkrish    10/02/03 - Creation
  
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
