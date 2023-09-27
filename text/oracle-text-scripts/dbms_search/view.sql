exec dbms_search.drop_index('ed')

drop table emp;
drop table dept;

create table emp (empid number primary key, name varchar2(30), deptid number);
create table dept (deptid number primary key, name varchar2(30), manager number);

insert into emp values (1, 'John Smith', 1);
insert into dept values (1, 'Sales', 1);

drop view empdept;

create view empdept as select empid, e.name ename, d.name dname
from emp e, dept d
where e.deptid = d.deptid;

exec dbms_search.create_index('ed')
exec dbms_search.add_source('ed', 'empdept')

exec dbms_search.create_index('ed')
