set echo on trims on tab off

drop table sales purge;

create table sales (id number(10), num1 number(10), num2 number(10), num3 number(10), num4 number(10), txt1 varchar2(10));

insert into sales
select rownum,rownum,mod(rownum,1000),mod(rownum,10),null,dbms_random.string('U',10) from dual connect by rownum<10000;

commit;

create unique index salesi on sales (id);

exec dbms_stats.gather_table_stats (ownname=>user,tabname=>'sales',method_opt=>'for all columns size 1');

var t1 varchar2(40)
var t2 varchar2(40)

exec dbms_lock.sleep(2);

@hist

select count(*) from sales where txt1 > 'A';
select count(*) from sales where num3>1;

insert into sales
select rownum+100000,rownum,mod(rownum,2000),mod(rownum,20),null,dbms_random.string('U',10) from dual connect by rownum<10000;
commit;

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for all columns size auto')

@hist

select count(*) from sales where txt1 > 'A';
select count(*) from sales where num3>1;

insert into sales
select rownum+200000,rownum,mod(rownum,2000),mod(rownum,40),null,dbms_random.string('U',10) from dual connect by rownum<10000;
commit;

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for all columns size auto')

@hist

exec dbms_lock.sleep(2);

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for all columns size 1')

exec dbms_stats.gather_table_stats(ownname=>user,tabname=>'sales',method_opt=>'for columns size 254 num2')

@hist

set echo off
@h_hist sales user
