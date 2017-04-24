drop table tab1 purge;
drop table tab2 purge;

create table tab1 (
  id        number(10)
 ,cust      number(10)
 ,num       number(10)
 ,txt       varchar2(100))
/

create table tab2 (
  id        number(10)
 ,ty        varchar2(10)
 ,num       number(10)
 ,txt       varchar2(100))
/

insert into tab1
select rownum,mod(rownum,10),rownum,'Desc'
from   dual connect by rownum < 10000;

insert into tab2
select mod(rownum,100),'T'||rownum,rownum,'Desc'
from   dual connect by rownum < 100;

create unique index tab1pk on tab1 (id);
create unique index tab2pk on tab2 (id);
create index tab2tyi on tab2(ty);

exec dbms_stats.gather_table_stats(user,'tab1');
exec dbms_stats.gather_table_stats(user,'tab2');
