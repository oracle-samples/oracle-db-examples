-- Execute this script on PCATALOG PDB database as app_schema user

set echo on

alter session enable shard ddl;

DROP TABLE IF EXISTS CUSTOMER cascade constraint;
CREATE DUPLICATED TABLE CUSTOMER
  (
    CustId      VARCHAR2(60) NOT NULL,
    FirstName   VARCHAR2(60),
    LastName    VARCHAR2(60),
    CustProfile VARCHAR2(4000),
    CONSTRAINT PK_CUSTOMER PRIMARY KEY (CustId),
    CONSTRAINT JSON_CUSTOMER CHECK (CustProfile IS JSON)
  )
  TABLESPACE products
;

-- NOTE: sharded table can not reference duplicated table
-- NOTE: sharded tables can not use partition by reference
-- ORA-14039: partitioning columns must form a subset of key columns of a UNIQUE

DROP TABLE IF EXISTS ORDERS_ITEM cascade constraints;
DROP TABLE IF EXISTS ORDERS cascade constraints;

CREATE SHARDED TABLE ORDERS
  (
    OrderId     INTEGER NOT NULL,
    CustId      VARCHAR2(60) NOT NULL,
    OrderDate   TIMESTAMP NOT NULL,
    SumTotal    NUMBER(19,4),
    Status      CHAR(4),
    COUNTRY     VARCHAR2(40) NOT NULL,
    CONSTRAINT  pk_orders PRIMARY KEY (COUNTRY, CustId, OrderId)
  )
  PARTITION BY LIST (COUNTRY)
  ( PARTITION EMEA VALUES ('Denmark', 'France', 'Germany', 'Poland', 'Spain', 'United Kingdom') TABLESPACE EMEA
  , PARTITION APAC VALUES ('India', 'Australia', 'Japan', 'New Zealand', 'Saudi Arabia', 'Singapore', 'Turkey') TABLESPACE APAC)
;

DROP TABLE IF EXISTS ORDERS_ITEM cascade constraints;

CREATE SHARDED TABLE ORDERS_ITEM
  (
    OrderId     INTEGER NOT NULL,
    CustId      VARCHAR2(60) NOT NULL,
    ItemId      INTEGER NOT NULL,
    Price       NUMBER(19,4),
    Status      CHAR(4),
    COUNTRY     VARCHAR2(40) NOT NULL,
    CONSTRAINT  pk_orderiterms PRIMARY KEY (COUNTRY, CustId, OrderId, ItemId),
    CONSTRAINT  fk_orderitemts_parent FOREIGN KEY (COUNTRY, CustId, OrderId) REFERENCES ORDERS(COUNTRY, CustId, OrderId) ON DELETE CASCADE
  ) PARTITION BY REFERENCE (fk_orderitemts_parent)
;
