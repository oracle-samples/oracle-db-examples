Rem
Rem $Header: rdbms/demo/dmardemo.sql /main/16 2016/08/16 23:01:14 madhpand Exp $
Rem
Rem dmardemo.sql
Rem
Rem Copyright (c) 2003, 2016, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      dmardemo.sql - Sample program for the DBMS_DATA_MINING package.
Rem
Rem    DESCRIPTION
Rem      This script creates an association model
Rem      using the Apriori algorithm
Rem      and data in the SH (Sales History) schema in the RDBMS. 
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    madhpand    07/15/16 - create view with parallel hint and set parallel 4
Rem    gayyappa    09/23/15 - Add demo for AR transactional data views
Rem    bmilenov    09/23/15 - bug-21394151: view cleanup
Rem    dbai        02/19/15 - Add demo for aggregates and model views
Rem    amozes      01/25/12 - updates for 12c
Rem    ramkrish    02/04/08 - Add Transactional Input samples
Rem    ramkrish    06/14/07 - remove commit after settings
Rem    ramkrish    10/25/07 - replace deprecated get_model calls with catalog
Rem                           queries
Rem    dmukhin     12/13/06 - bug 5557333: AR scoping
Rem    ktaylor     07/11/05 - minor edits to comments
Rem    ramkrish    03/04/05 - 4222328: fix sales_trans queries for dupl custids
Rem    jcjeon      01/18/05 - add column format 
Rem    ramkrish    09/16/04 - add data analysis and comments/cleanup
Rem    ramkrish    07/30/04 - lrg 1726339 - comment out itemsetid
Rem                           hash-based group by no longer guarantees
Rem                           ordered itemset ids
Rem    xbarr       06/25/04 - xbarr_dm_rdbms_migration
Rem    mmcracke    12/11/03 - Remove RuleID from results display 
Rem    ramkrish    10/20/03 - ramkrish_txn109085
Rem    ramkrish    10/02/03 - Creation
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 140
SET echo ON

-- ODM API accepts data both in relational (2D) form, and
-- transactional form for Association Rules.
-- Transactional data is the more common form of input for
-- this type of problem, so the demo shows examples of
-- processing transactional input.

-----------------------------------------------------------------------
--                            SET UP AND ANALYZE THE DATA
-----------------------------------------------------------------------

-- Cleanup old dataset for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP VIEW sales_trans_cust';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------
-- DATA
-------
-- The data for this sample is composed from a small subset of
-- sales transactions in the SH schema - listing the (multiple)
-- items bought by a set of customers with ids in the range
-- 100001-104500. It also lists the dollar amount sold for
-- each item. Note that this data is based on customer id,
-- not "basket" id (as in the case of true market basket data).
--
-- Market basket or sales datasets are transactional in nature,
-- and form fact tables in a typical data warehouse.
--
CREATE VIEW sales_trans_cust AS
 SELECT cust_id, prod_name, prod_category, amount_sold
 FROM (SELECT a.cust_id, b.prod_name, b.prod_category,
             a.amount_sold
        FROM sh.sales a, sh.products b
       WHERE a.prod_id = b.prod_id AND
             a.cust_id between 100001 AND 104500);

-----------
-- ANALYSIS
-----------
-- Association Rules in ODM works best on sparse data - i.e. data where
-- the average number of attributes/items associated with a given case is
-- a small percentage of the total number of possible attributes/items.
-- This is true of most market basket datasets where an average customer
-- purchases only a small subset of items from a fairly large inventory
-- in the store.
--
-- This section provides a rough outline of the analysis to be performed
-- on data used for Association Rules model build.
--
-- 1. Compute the cardinality of customer id and product (940, 14)
SELECT COUNT(DISTINCT cust_id) cc, COUNT(DISTINCT prod_name) cp
  FROM sales_trans_cust;

-- 2. Compute the density of data (21.31)
column density format a18
SELECT TO_CHAR((100 * ct)/(cc * cp), 99.99) density
  FROM (SELECT COUNT(DISTINCT cust_id) cc,
               COUNT(DISTINCT prod_name) cp,
               COUNT(*) ct
          FROM sales_trans_cust);

-- 3. Common items are candidates for removal during model build, because
--    if a majority of customers have bought those items, the resulting
--    rules do not have much value. Find out most common items. For example,
--    the query shown below determines that Mouse_Pad is most common (303).
--
--    Since the dataset is small, we will skip common item removal.
--
column prod_name format a40
SELECT prod_name, count(prod_name) cnt
  FROM sales_trans_cust
GROUP BY prod_name
ORDER BY cnt DESC, prod_name DESC;

-- 4. Compute the average number of products purchased per customer (2.98)
--    3 out of 11 corresponds to the density we computed earlier.
--
column avg_num_prod format a16
SELECT TO_CHAR(AVG(cp), 999.99) avg_num_prod
  FROM (SELECT COUNT(prod_name) cp
          FROM sales_trans_cust
        GROUP BY cust_id);

-- 5. Compute the minimum and maximum dollar amount sold 
--    for each item (7.99, 1299.99).
SELECT MIN(amount_sold), MAX(amount_sold) FROM sales_trans_cust;

--------------------------------------------------------------------------------
--
-- Create view sales_trans_cust_parallel with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW sales_trans_cust_parallel AS SELECT /*+ parallel (4)*/ * FROM sales_trans_cust;

-----------------------------------------------------------------------
--         SAMPLE PROBLEM USING TRANSACTIONAL (pair/triple) INPUT
-----------------------------------------------------------------------

-- ODM API accepts data both in relational (2D) form and
-- transactional form for Association Rules.
--
-- The transactional input is a two column table of the form:
-- (transaction_id, item_id)
-- or a three column table of the form:
-- (transaction_id, item_id, item_value)
-- where we use the case_id to represent a transaction_id.
--
-- Example of a two column transactional table is:
-- (transaction_id, item_id)
-- (1, 1)
-- (1, 4)
-- (2, 2)
-- or
-- (1, 'apple')
-- (1, 'pear')
-- (2, 'banana')
--
-- Example of a three column transactional table is:
-- (transaction_id, item_id, item_value)
-- (1, 'apple', 2)
-- (1, 'banana', 4)
-- (2, 'apple', 1)
-- (2, 'banana', 2)
-- or
-- (1, 'wine', 'red')
-- (1, 'wine', 'white')
-- (1, 'cheese', 'swiss')
-- (2, 'cheese', 'provolone')
-- which allows you to treat different (item_id, item_val) pairings
-- for a given transaction essentially as different, unique items.
--

--------------------------------
-- PREPARE BUILD (TRAINING) DATA
--
-- Data for AR modeling may need binning if it contains numerical data.

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ar_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- The default (and only) algorithm for association rules is
-- Apriori AR. However, we need a settings table 
-- to override the default Min Support, Min Confidence,
-- and Max items settings.
-- Add settings for Transaction Input - the presence
-- of an Item Id column specification indicates to the
-- API that the input is transactional
-- 
set echo off
CREATE TABLE ar_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));
set echo on

BEGIN       
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.asso_min_support,0.1);
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.asso_min_confidence,0.1);
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.asso_max_rule_length,3);
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.odms_item_id_column_name, 'PROD_NAME');
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.asso_aggregates, 'AMOUNT_SOLD');
  COMMIT;
END;
/

BEGIN DBMS_DATA_MINING.DROP_MODEL('AR_SH_SAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

----------------------------------------------
-- Build AR model with transactional input
--
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'AR_SH_SAMPLE',
    mining_function     => DBMS_DATA_MINING.ASSOCIATION,
    data_table_name     => 'sales_trans_cust_parallel',
    case_id_column_name => 'cust_id',
    settings_table_name => 'ar_sh_sample_settings'
    );
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a30
SELECT setting_name, setting_value
  FROM user_mining_model_settings
 WHERE model_name = 'AR_SH_SAMPLE'
ORDER BY setting_name;

-----------------------------------------------------------------------
--                            TEST THE MODEL
-----------------------------------------------------------------------

-- Association rules do not have a predefined test metric.
--
-- Two indirect measures of modeling success are:
--
-- 1. Number of Rules generated: The optimal number of rules is
--    application dependent. In general, an overwhelming number of
--    rules is undesirable for user interpretation. More rules take
--    longer to compute, and also consume storage and CPU cycles.
--    You avoid too many rules by increasing the value for support.
-- 
-- 2. Relevance of rules
--    This can be determined only by user inspection of rules, since
--    it is application dependent. Ideally, we want to find rules with
--    high confidence and with non-obvious patterns. The value for
--    confidence is an indicator of the strength of the rule - so
--    you could set the confidence value high in conjunction with
--    support and see if you get high quality rules.
-- 
-- 3. Frequent itemsets provide an insight into co-occurrence of items.

-----------------------------------------------------------------------
--                            DISPLAY MODEL CONTENT
-----------------------------------------------------------------------

-------------------------------------------------------------
-- Display Top-10 Frequent Itemsets
--
break on itemset_id skip 1;
column item format a40
SELECT item, support, number_of_items
  FROM (SELECT I.attribute_subname AS item,
               F.support,
               F.number_of_items
          FROM TABLE(DBMS_DATA_MINING.GET_FREQUENT_ITEMSETS(
                       'AR_SH_SAMPLE',
                       10)) F,
               TABLE(F.items) I
        ORDER BY number_of_items, support, item);

----------------------------------------------------------
-- Display Top-10 Association Rules
--
SET line 300
column antecedent format a30
column consequent format a20
column supp format 9.999
column conf format 9.999
SELECT a.attribute_subname antecedent,
       c.attribute_subname consequent,
       rule_support supp,
       rule_confidence conf,
       row_number() over (partition by rule_id order by a.attribute_subname) piece
  FROM TABLE(DBMS_DATA_MINING.GET_ASSOCIATION_RULES('AR_SH_SAMPLE', 10)) T,
       TABLE(T.consequent) C,
       TABLE(T.antecedent) A
 ORDER BY conf DESC, supp DESC, piece;

-----------------------------------------------------------------------
--                        DISPLAY MODEL CONTENT USING VIEWS
-----------------------------------------------------------------------

-- In 12.2, aggregation functionality is added to Association Rules
-- model. The model views, DM$VI<ModelName> and DM$VR<ModelName>, are
-- provided as the new output interface.

-- Get a list of model views
col view_name format a30
col view_type format a50
SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='AR_SH_SAMPLE'
  ORDER BY view_name;

----------------------------------------------------------
-- Using DM$VI<ModelName> to display Top-10 Frequent Itemsets.
-- The dollar amount sold of each item is displayed.
--
column item format a40
column amount_sold format 999999.99
column support format 9.999
column number_of_items format 99

set echo off
SELECT items.item, items.amount_sold, support, number_of_items
FROM
(SELECT * FROM(
  SELECT itemset,
         number_of_items,
         support
  FROM   DM$VIAR_SH_SAMPLE
  ORDER BY number_of_items, support)
  WHERE  ROWNUM <=10) fis,
  XMLTABLE ('/itemset/item'  PASSING fis.itemset
             COLUMNS 
             item     varchar2(40)  PATH 'item_name',
             amount_sold  number    PATH 'ASSO_AGG0'
         ) items
ORDER BY number_of_items, support, item;
set echo on

----------------------------------------------------------
-- Using DM$VR<ModelName> to display Top-10 Association Rules.
-- For each rule, the dollar amount sold of the consequent item
-- is displayed.
--
SET line 300
column antecedent format a30
column consequent format a20
column supp format 9.999
column conf format 9.999
column con_amount format 99999.99
column piece format 99

set echo off
SELECT ant_items.item antecedent,
       consequent_name consequent,
       con_rule_amount_sold con_amount, 
       rule_support supp, rule_confidence conf,
       ant_items.piece
FROM   (SELECT * FROM (SELECT antecedent, consequent_name, rule_support,
                              rule_confidence, con_rule_amount_sold
                       FROM   DM$VRAR_SH_SAMPLE
                       ORDER BY rule_confidence DESC, rule_support DESC)
        WHERE  ROWNUM <=10) r,
  XMLTABLE ('/itemset/item'  PASSING r.ANTECEDENT
             COLUMNS 
             item     varchar2(30)  PATH 'item_name',
             piece  for ordinality
         ) ant_items
ORDER BY conf DESC, supp DESC, piece;
set echo on

--- ------------------------------------------------------------------
--- Now we shall build the model with a 2 column transactional input table
--- We choose only cust_id and prod_name from the sales_trans_cust view
--- Clear the settings table and specify the settings for this model build.
--- Use dbms_data_mining.odms_item_id_column_name to indicate transactional 
--- input

CREATE OR REPLACE VIEW sales_trans_cust_2col AS
SELECT cust_id, prod_name from sales_trans_cust;

--------------------------------------------------------------------------------
--
-- Create view sales_trans_2col_parallel with a parallel hint
--
--------------------------------------------------------------------------------
CREATE or REPLACE VIEW sales_trans_2col_parallel AS SELECT /*+ parallel (4)*/ * FROM sales_trans_cust_2col;

truncate table ar_sh_sample_settings;       
BEGIN
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.asso_min_support,0.1);
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.asso_min_confidence,0.1);
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.asso_max_rule_length,3);
  INSERT INTO ar_sh_sample_settings VALUES
  (dbms_data_mining.odms_item_id_column_name, 'PROD_NAME');
COMMIT;
END;
/

BEGIN DBMS_DATA_MINING.DROP_MODEL('AR_SH_SAMPLE_2COL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'AR_SH_SAMPLE_2COL',
    mining_function     => DBMS_DATA_MINING.ASSOCIATION,
    data_table_name     => 'sales_trans_2col_parallel',
    case_id_column_name => 'cust_id',
    settings_table_name => 'ar_sh_sample_settings'
    );
END;
/

---- Lets display the model content using views. 
---- There are 2 additional views for transactional data
---- i.e DM$VTAR_SH_SAMPLE_2COL and DM$VAAR_SH_SAMPLE_2COL that give 
---- information about the frequent item sets and rules. 
---- in addition to DM$VIAR_SH_SAMPLE_2COL and DM$VRAR_SH_SAMPLE_2COL.
---- We shall use DM$VT and DM$VA to display the Top-10 frequent itemsets
---- and Top-10 association rules

SELECT view_name, view_type FROM user_mining_model_views
  WHERE model_name='AR_SH_SAMPLE_2COL'
  ORDER BY view_name;

set echo off
column item_name format a40
select * from
( select item_name, support, number_of_items from DM$VTAR_SH_SAMPLE_2COL
  ORDER BY number_of_items, support
) where rownum <=10
ORDER BY number_of_items, support, item_name;


select * from
(
SELECT antecedent_predicate antecedent,
       consequent_predicate consequent,
       rule_support supp, rule_confidence conf, number_of_items num
from DM$VAAR_SH_SAMPLE_2COL
ORDER BY rule_confidence DESC, rule_support DESC)
WHERE  ROWNUM <=10 
order by antecedent, consequent;

set echo on

