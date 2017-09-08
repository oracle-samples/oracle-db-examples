drop table sales purge
/

create table sales (id number(10), num number(10));

insert into sales
select rownum,rownum
from   dual connect by rownum < 100000;

commit;

create index salesi on sales (id);

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'SALES')
