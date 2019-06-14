set echo on

drop table sales purge;

create table sales (id number(10), num1 number(10), num2 number(10), num3 number(10), num4 number(10), txt1 varchar2(10))
partition by range (id) (
partition p1 values less than (5000),
partition p2 values less than (20000),
partition p3 values less than (300000));

insert into sales
select rownum,rownum,mod(rownum,1000),mod(rownum,10),null,dbms_random.string('U',10) from dual connect by rownum<10000;

commit;

create unique index salesi on sales (id);

exec dbms_stats.gather_table_stats (ownname=>user,tabname=>'sales',method_opt=>'for all columns size 1');

var t1 varchar2(40)
var t2 varchar2(40)

exec dbms_lock.sleep(2);

@hist

insert into sales
select rownum+100000,rownum,mod(rownum,2000),mod(rownum,20),null,dbms_random.string('U',10) from dual connect by rownum<10000;
commit;

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for all columns size 254')

@hist

insert into sales
select rownum+200000,rownum,mod(rownum,2000),mod(rownum,40),null,dbms_random.string('U',10) from dual connect by rownum<10000;
commit;

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for all columns size 254')

@hist

exec dbms_lock.sleep(2);

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for all columns size 1')

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for columns size 254 num2')

@hist

set echo off
@h_phist sales scomp
