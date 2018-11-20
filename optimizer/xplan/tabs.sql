--
-- Create our test tables
--
drop table table_10 purge;
drop table table_100 purge;
drop table table_1000 purge;
drop table table_10000 purge;
drop table table_100000 purge;

create table table_10 (id number(10) not null, fcol number(10) not null);
create table table_100 (id number(10) not null, fkcol number(10) not null, fcol number(10) not null);
create table table_1000 (id number(10) not null, fkcol number(10) not null, fcol number(10) not null);
create table table_10000 (id number(10) not null, fkcol number(10) not null, fcol number(10) not null);
create table table_100000 (id number(10) not null, fkcol number(10) not null, fcol number(10) not null);

insert /*+ APPEND */ into table_10 
select rownum,rownum
from   dual connect by rownum <= 10;
commit;

insert /*+ APPEND */ into table_100
select rownum,mod(rownum,10),rownum
from   dual connect by rownum <= 100;
commit;

insert /*+ APPEND */ into table_1000 
select rownum,mod(rownum,100),rownum
from   dual connect by rownum <= 1000;
commit;

insert /*+ APPEND */ into table_10000 
select rownum,mod(rownum,1000),rownum
from   dual connect by rownum <= 10000;
commit;

insert /*+ APPEND */ into table_100000
select rownum,mod(rownum,10000),rownum
from   dual connect by rownum <= 100000;
commit;

exec dbms_stats.gather_table_stats(user,'table_10');
exec dbms_stats.gather_table_stats(user,'table_100');
exec dbms_stats.gather_table_stats(user,'table_1000');
exec dbms_stats.gather_table_stats(user,'table_10000');
exec dbms_stats.gather_table_stats(user,'table_100000');

drop table employees purge;
drop table tasks purge;
create table employees (id number(10) not null, ename varchar2(100) not null, etype number(10) not null, details varchar2(1000));
create table tasks (id number(10) not null, tname varchar2(100) not null, emp_id number(10) not null, ttype number(10) not null, details varchar2(1000));

begin
  for i in 1..10000
  loop
     insert into employees values (i,
                                   'Employee Name '||i, 
                                   mod(i,500) + 1, 
                                   dbms_random.string('u',1000));
  end loop;
  for i in 1..20000
  loop
     insert into tasks values (i,'Task Name '||i, mod(i,10000) + 1, mod(i,500) + 1, dbms_random.string('u',1000));
  end loop;
  commit;
end;
/

@@ind

exec dbms_stats.gather_table_stats(user,'employees');
exec dbms_stats.gather_table_stats(user,'tasks');
