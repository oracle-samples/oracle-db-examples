
PROMPT ***********************************************************
PROMPT 
PROMPT WARNING!
PROMPT About to drop tables 'roles', 'employees' and 'departments'
PROMPT
PROMPT ***************************************************************************************************************

PAUSE  Press <cr> to continue...

drop table roles purge;
drop table employees purge;
drop table departments purge;

create table employees (id number(10) not null, ename varchar2(100) not null, dept_id number(10) not null, role_id number(10) not null, staffno number(10) not null);
create table departments (id number(10) not null, dname varchar2(100) not null);
create table roles (id number(10) not null, rname varchar2(100) not null);

begin
  for i in 1..500
  loop
     insert into employees values (i,'Employee Name '||i, mod(i,10) + 1, mod(i,10), i);
  end loop;
  for i in 1..10
  loop
     insert into departments values (i,'Department Name '||i);
     insert into roles values (i,'Role Name '||i);
     insert into roles values (i+11,'Role Name '||i);
  end loop;
  commit;
end;
/

exec dbms_stats.gather_table_stats(user,'employees');
exec dbms_stats.gather_table_stats(user,'departments');
exec dbms_stats.gather_table_stats(user,'roles');
