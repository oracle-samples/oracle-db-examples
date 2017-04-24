drop table sales purge;

create table sales (
  id number(10)
, sale_date date);

insert into sales
select level, sysdate-rownum/1000
from   dual
connect by level <= 500000
/

create index salesi ON sales (sale_date);

insert into sales values (100000, to_date(sysdate+1000));
commit;

--
-- Make sure that we don't let histograms help us out here
--
exec dbms_stats.gather_table_stats(user, 'sales', method_opt=>'for all columns size 1')


