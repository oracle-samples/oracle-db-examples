-- Must build explain table for autotrace

set echo off
@?\rdbms\admin\utlxplan.sql
set echo on
set autotrace on explain

select id, price, descrip from bike_items_g
where contains (descrip, 'wheel') > 0
order by price;

select id, price, descrip from bike_items_p
where contains (descrip, 'wheel') > 0
order by price;

select id, price, descrip from bike_items_g
where contains (descrip, 'wheel') > 0
and price <= 50;

select id, price, descrip from bike_items_p
where contains (descrip, 'wheel') > 0
and price <= 50;


set autotrace off
