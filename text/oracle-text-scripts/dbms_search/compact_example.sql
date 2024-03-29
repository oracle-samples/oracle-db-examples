exec dbms_search.drop_index('PROD')

drop table PRODUCTS;
drop table CUSTOMERS;

create table PRODUCTS ( id number primary key, description  varchar2(2000));
create table CUSTOMERS ( id number primary key, address json );

insert into PRODUCTS values 
    (1, 'product1 description'); 
insert into CUSTOMERS values 
    (99, '{ "city": "Richmond", "country": "United Kingdom"}');

-- Create the DBMS_SEARCH index (PROD):

exec DBMS_SEARCH.CREATE_INDEX('PROD')

-- Populate the index with tables:

exec DBMS_SEARCH.ADD_SOURCE('PROD', 'PRODUCTS')
exec DBMS_SEARCH.ADD_SOURCE('PROD', 'CUSTOMERS')

-- The data is stored in a text table called PROD, which matches your index name.
-- View the virtual indexed document:

select DBMS_SEARCH.GET_DOCUMENT('PROD',METADATA) from PROD;

-- Run a query which fetches metadata from the index

select metadata from PROD where contains(data,'product1')>0;

-- Now run a query to get stuff where there is match in the customers address

select metadata from PROD where json_textcontains(data, '$.ROGER.CUSTOMERS.ADDRESS', 'Richmond');

-- Now join that with the base table so we get the actual original data back

column firstname format a15
column lastname format a15
column address format a30

select c.id, c.address
from PROD P, CUSTOMERS c
where json_textcontains(data, '$.ROGER.CUSTOMERS.ADDRESS', 'Richmond')
and p.metadata."KEY"."ID" = c.id;

