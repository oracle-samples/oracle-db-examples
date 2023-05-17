REM   Script: Analytics - LAG and LEAD functions
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script looks at the lag and lead functions.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table ORDERS purge;

create table ORDERS 
( order_id     int,
  status_date  date,
  status       varchar2(20)
);

insert into ORDERS values (11700, date '2016-01-03', 'New');

insert into ORDERS values (11700, date '2016-01-04', 'Inventory Check');

insert into ORDERS values (11700, date '2016-01-05', 'Inventory Check');

insert into ORDERS values (11700, date '2016-01-06', 'Inventory Check');

insert into ORDERS values (11700, date '2016-01-07', 'Inventory Check');

insert into ORDERS values (11700, date '2016-01-08', 'Inventory Check');

insert into ORDERS values (11700, date '2016-01-09', 'Awaiting Signoff');

insert into ORDERS values (11700, date '2016-01-10', 'Awaiting Signoff');

insert into ORDERS values (11700, date '2016-01-11', 'Awaiting Signoff');

insert into ORDERS values (11700, date '2016-01-12', 'In Warehouse');

insert into ORDERS values (11700, date '2016-01-13', 'In Warehouse');

insert into ORDERS values (11700, date '2016-01-14', 'In Warehouse');

insert into ORDERS values (11700, date '2016-01-15', 'Awaiting Signoff');

insert into ORDERS values (11700, date '2016-01-16', 'Awaiting Signoff');

insert into ORDERS values (11700, date '2016-01-17', 'Payment Pending');

insert into ORDERS values (11700, date '2016-01-18', 'Payment Pending');

insert into ORDERS values (11700, date '2016-01-19', 'Awaiting Signoff');

insert into ORDERS values (11700, date '2016-01-20', 'Awaiting Signoff');

insert into ORDERS values (11700, date '2016-01-21', 'Delivery');

insert into ORDERS values (11700, date '2016-01-22', 'Delivery');

commit


select * from orders order by 1,2;

select status, min(status_date) from_date, max(status_date) to_date
from orders
group by status
order by 2;

select   
  order_id,
  status_date,
  status,
  lag(status,1) over 
    (partition by order_id order by status_date) lag_status
from ORDERS
order by 1,2;

select   
  order_id,
  status_date,
  status,
  lag(status,1) over (partition by order_id order by status_date) lag_status,
  lead(status,1) over (partition by order_id order by status_date) lead_status
from ORDERS
order by 1,2;

select   order_id,
         status_date,
         status,
         lag(status) over (partition by order_id order by status_date) lag_status,
         lead(status) over (partition by order_id order by status_date) lead_status,
         lag(status_date) over (partition by order_id order by status_date) lag_status_date,
         lead(status_date) over (partition by order_id order by status_date) lead_status_date
from ORDERS
order by 1,2;

select 
  order_id, 
  status, 
  lag(status_date) over (partition by order_id order by status_date)  from_date,
  status_date to_date
from (
  select 
    order_id,
    status_date,
    status,
    lag(status) over (partition by order_id order by status_date) lag_status,
    lead(status) over (partition by order_id order by status_date) lead_status
  from ORDERS
  )
where lag_status is null
       or lead_status is null
       or lead_status <> status
order by 1,3 nulls first;

