-- DISCLAIMER:
-- This script is provided for educational purposes only. It is 
-- NOT supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts initially 
-- on a test instance.

set timing off
set echo off
set lines 400 pages 1000
set feedback 1
set pause off
set echo on


PROMPT Connect to the Attribute Clusters/Zone Map Schema
connect aczm12c/oracle_4U

PROMPT     Drop SALES_SOURCE table
drop table sales_source
/
--
PROMPT Create the SALES_SOURCE table
PROMPT This will provide us with a consistent dataset
PROMPT for any fact tables we choose to create later on
--
CREATE TABLE sales_source
  (
    order_id          NUMBER(20)    NOT NULL ,
    order_item_number NUMBER(3)     NOT NULL ,
    sale_date         DATE          NOT NULL ,
    delivered         DATE          ,
    sale_agent        VARCHAR2(100) NOT NULL ,
    product_id       NUMBER(10)    NOT NULL ,
    amount            NUMBER(10,2)  NOT NULL ,
    quantity          NUMBER(5)     NOT NULL ,
    location_id       NUMBER(20)    NOT NULL ,
    warehouse         VARCHAR2(100) NOT NULL
  )
/

PROMPT     Drop the LOCATIONS table
DROP TABLE locations
/

PROMPT     Create the LOCATIONS table
CREATE TABLE locations
  (
    location_id NUMBER(20) ,
    state       VARCHAR2(100) NOT NULL ,
    county      VARCHAR2(100) NOT NULL ,
    description VARCHAR2(1000) NOT NULL ,
    PRIMARY KEY (location_id)
  )
/

PROMPT     Drop the PRODUCTS table
DROP TABLE products
/

PROMPT     Create the PRODUCTS table
CREATE TABLE products
  (
    product_id          NUMBER(20) ,
    product_name        VARCHAR2(20) ,
    product_description VARCHAR2(100) ,
    PRIMARY KEY(product_id)
  )
/




