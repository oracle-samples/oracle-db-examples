set echo on

alter session force parallel query parallel 4;
alter session force parallel dml parallel 4;
create or replace directory TPCSD_LOAD_DIR as '/vol/TPCDS/DATA';

insert /*+ append */ into WAREHOUSE select * from X_WAREHOUSE;
insert /*+ append */ into SHIP_MODE select * from X_SHIP_MODE;
insert /*+ append */ into TIME_DIM select * from X_TIME_DIM;
insert /*+ append */ into REASON select * from X_REASON;
insert /*+ append */ into INCOME_BAND select * from X_INCOME_BAND;
insert /*+ append */ into ITEM select * from X_ITEM;
insert /*+ append */ into STORE select * from X_STORE;
insert /*+ append */ into CALL_CENTER select * from X_CALL_CENTER;
insert /*+ append */ into CUSTOMER select * from X_CUSTOMER;
insert /*+ append */ into WEB_SITE select * from X_WEB_SITE;
insert /*+ append */ into STORE_RETURNS select * from X_STORE_RETURNS;
insert /*+ append */ into HOUSEHOLD_DEMOGRAPHICS select * from X_HOUSEHOLD_DEMOGRAPHICS;
insert /*+ append */ into WEB_PAGE select * from X_WEB_PAGE;
insert /*+ append */ into PROMOTION select * from X_PROMOTION;
insert /*+ append */ into CATALOG_PAGE select * from X_CATALOG_PAGE;
insert /*+ append */ into INVENTORY select * from X_INVENTORY;
insert /*+ append */ into CATALOG_RETURNS select * from X_CATALOG_RETURNS;
insert /*+ append */ into WEB_RETURNS select * from X_WEB_RETURNS;
insert /*+ append */ into WEB_SALES select * from X_WEB_SALES;
insert /*+ append */ into CATALOG_SALES select * from X_CATALOG_SALES;
insert /*+ append */ into STORE_SALES select * from X_STORE_SALES;
insert /*+ append */ into CUSTOMER_ADDRESS select * from X_CUSTOMER_ADDRESS;
insert /*+ append */ into CUSTOMER_DEMOGRAPHICS select * from X_CUSTOMER_DEMOGRAPHICS;
insert /*+ append */ into DATE_DIM select * from X_DATE_DIM;

commit;
