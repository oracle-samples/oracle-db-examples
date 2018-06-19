drop table t1;
drop table t2;

create table t1 (id number(10) not null, val1 number(10) not null, val2 number(10) not null);

create table t2 (id number(10) not null, val1 number(10) not null, val2 number(10) not null)
partition by range (id) (
  partition p1 values less than (100000)
, partition p2 values less than (200000)
)
/

insert into t1 select rownum,rownum,rownum from (
select 1 
from dual connect by rownum < 10000);

insert into t2 select rownum,rownum,rownum from (
select 1 
from dual connect by rownum < 10000);

insert into t2 select rownum+100000,rownum,rownum from (
select 1 
from dual connect by rownum < 10000);


create index t1i on t1 (id);
create index t2i on t2 (id) local (
partition p1i,
partition p2i);

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'t1');
exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'t2');
