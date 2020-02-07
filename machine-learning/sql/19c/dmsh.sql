-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL)
-- 
--   Setup - Creates Demo Views and Tables - dmsh.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
--
--
-- dmsh.sql
--
--
--    NAME
--    dmsh.sql
--
--    DESCRIPTION
--      This script creates views and tables using SH data
--      in the schema of the data mining user. These tables/views
--      are the datasets used by the Oracle Data Mining demo programs.
--      This script also creates a text policy for text mining.
--    NOTES
--       The script assumes that the full SH schema is already created and the
--       necessary SELECTs have been granted (See dmshgrants.sql). This script runs in 
--       the schema of the data mining user.
--       mining_data_*_v views : Used for mining (no text)
--       mining_*_text views: Used for mining with text 
--
--------------------------------------------------------------------------------
--
-- Creates data mining views on SH data
--

--------------------------------------------------------------------------------
-- View to join and filter data
-- CUST_YEAR_OF_BIRTH column is transformed to an AGE
CREATE OR REPLACE VIEW mining_data AS
SELECT
 a.CUST_ID, a.CUST_GENDER,
 2003-a.CUST_YEAR_OF_BIRTH AGE,
 a.CUST_MARITAL_STATUS, c.COUNTRY_NAME, a.CUST_INCOME_LEVEL, b.EDUCATION,
 b.OCCUPATION, b.HOUSEHOLD_SIZE, b.YRS_RESIDENCE, b.AFFINITY_CARD,
 b.BULK_PACK_DISKETTES, b.FLAT_PANEL_MONITOR, b.HOME_THEATER_PACKAGE,
 b.BOOKKEEPING_APPLICATION, b.PRINTER_SUPPLIES, b.Y_BOX_GAMES,
 b.os_doc_set_kanji, b.comments 
FROM
 sh.customers a,
 sh.supplementary_demographics b,
 sh.countries c
WHERE
 a.CUST_ID = b.CUST_ID
 AND a.country_id  = c.country_id
 AND a.cust_id between 100001 and 104500;

--------------------------------------------------------------------------------
-- Build, test, and apply views (with text)
-- Build, test, and apply datasets are made non-overlapping by using
-- a predicate on cust_id.

CREATE OR REPLACE VIEW mining_build_text AS
SELECT *
FROM mining_data
WHERE cust_id between 101501 and 103000;

CREATE OR REPLACE VIEW mining_test_text AS
SELECT *
FROM mining_data
WHERE cust_id between 103001 and 104500;

CREATE OR REPLACE VIEW mining_apply_text AS
SELECT *
FROM mining_data
WHERE cust_id between 100001 and 101500;

--------------------------------------------------------------------------------
-- Build, test, and apply views
-- Same as above, but no text - COMMENTS column removed

CREATE OR REPLACE VIEW mining_data_build_v AS
SELECT CUST_ID, CUST_GENDER, AGE, CUST_MARITAL_STATUS, COUNTRY_NAME,
 CUST_INCOME_LEVEL, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE,
 YRS_RESIDENCE, AFFINITY_CARD, BULK_PACK_DISKETTES, FLAT_PANEL_MONITOR,
 HOME_THEATER_PACKAGE, BOOKKEEPING_APPLICATION, PRINTER_SUPPLIES,
 Y_BOX_GAMES, OS_DOC_SET_KANJI
FROM mining_build_text;

CREATE OR REPLACE VIEW mining_data_test_v AS
SELECT CUST_ID, CUST_GENDER, AGE, CUST_MARITAL_STATUS, COUNTRY_NAME,
 CUST_INCOME_LEVEL, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE,
 YRS_RESIDENCE, AFFINITY_CARD, BULK_PACK_DISKETTES, FLAT_PANEL_MONITOR,
 HOME_THEATER_PACKAGE, BOOKKEEPING_APPLICATION, PRINTER_SUPPLIES,
 Y_BOX_GAMES, OS_DOC_SET_KANJI
FROM mining_test_text;

CREATE OR REPLACE VIEW mining_data_apply_v AS
SELECT CUST_ID, CUST_GENDER, AGE, CUST_MARITAL_STATUS, COUNTRY_NAME,
 CUST_INCOME_LEVEL, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE,
 YRS_RESIDENCE, AFFINITY_CARD, BULK_PACK_DISKETTES, FLAT_PANEL_MONITOR,
 HOME_THEATER_PACKAGE, BOOKKEEPING_APPLICATION, PRINTER_SUPPLIES,
 Y_BOX_GAMES, OS_DOC_SET_KANJI
FROM mining_apply_text;

--------------------------------------------------------------------------------
-- Data for one class model
-- Only data for positive affinity card (one class) is used.

CREATE OR REPLACE VIEW mining_data_one_class_v AS
SELECT CUST_ID, CUST_GENDER, AGE, CUST_MARITAL_STATUS, COUNTRY_NAME,
 CUST_INCOME_LEVEL, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE, YRS_RESIDENCE
FROM mining_data_build_v
WHERE affinity_card = 1;

--------------------------------------------------------------------------------
--
-- Create view mining_data_build_parallel_v with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW mining_data_build_parallel_v AS SELECT /*+ parallel (4)*/ * FROM mining_data_build_v; 

--------------------------------------------------------------------------------
--
-- Create view  mining_data_one_class_pv with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW mining_data_one_class_pv AS SELECT /*+ parallel (4)*/ * FROM mining_data_one_class_v;

--------------------------------------------------------------------------------
--
-- Create view mining_data_test_parallel_v with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW mining_data_test_parallel_v AS SELECT /*+ parallel (4)*/ * FROM mining_data_test_v;

--------------------------------------------------------------------------------
--
-- Create view mining_data_apply_parallel_v with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW mining_data_apply_parallel_v AS SELECT /*+ parallel (4)*/ * FROM mining_data_apply_v;

--------------------------------------------------------------------------------
--
-- Create view mining_test_text_parallel with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW mining_test_text_parallel AS SELECT /*+ parallel (4)*/ * FROM mining_test_text;

