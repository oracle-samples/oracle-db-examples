exec dbms_search.drop_index('PROD')

drop table PRODUCTS;
drop table CUSTOMERS;

create table PRODUCTS (
    id           number primary key,
    price        number,
    description  varchar2(2000),
    in_stock     boolean,
    long_descrip clob );

create table CUSTOMERS (
    id           number primary key,
    firstname    varchar2(200),
    lastname     varchar2(200),
    address      json,
    added        date
    );

insert into PRODUCTS values 
    (1, 10, 'product1', 2000, 'product1 description'); 
insert into products values 
    (2, 2000, 'product2', 3, 'product2 description'); 
insert into CUSTOMERS values 
    (1, 'Robert', 'Smith', '{ "street": "1234 Example Street1", 
            "city": "Frogmortem", "state": "CA", 
            "country": "USA", "zip": 12345 }',
    SYSDATE);
insert into CUSTOMERS values 
    (99, 'John', 'Doe', '{ "street": "1234 Example Street2", 
            "city": "Richmond", "county": "Greater London", 
            "country": "United Kingdom", "postcode": "1234 567" }',
    SYSDATE);


-- Create the DBMS_SEARCH index (PRODUCERS):

exec DBMS_SEARCH.CREATE_INDEX('PROD')

-- Populate the index with tables:

exec DBMS_SEARCH.ADD_SOURCE('PROD', 'PRODUCTS')
exec DBMS_SEARCH.ADD_SOURCE('PROD', 'CUSTOMERS')

-- The data is stored in a text table called PROD, which matches your index name.
-- View the virtual indexed document:

select DBMS_SEARCH.GET_DOCUMENT('PROD',METADATA) from PROD;


-- Run a query which fetches metadata from the index

select metadata from PROD where contains(data,'product1 description or product2 description')>0;

-- Now run a query to get stuff where there is match in the customers address

select metadata from PROD where json_textcontains(data, '$.ROGER.CUSTOMERS.ADDRESS', 'Richmond');

-- Now join that with the base table so we get the actual original data back

column firstname format a15
column lastname format a15
column address format a30

select c.firstname, c.lastname, c.address
from PROD P, CUSTOMERS c
where json_textcontains(data, '$.ROGER.CUSTOMERS.ADDRESS', 'Richmond')
and p.metadata."KEY"."ID" = c.id;

