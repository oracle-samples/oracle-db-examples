drop table emp;
drop table dept;

create table emp( emp_no number primary key, ename varchar2(30), job varchar2(30), dept_no number);

create table dept( dept_no number primary key, dname varchar2(30), location varchar2(2));


insert into emp values (1, 'John Smith', 'Product Manager', 1);
insert into emp values (2, 'Fred Bloggs', 'Programmer', 1);
insert into emp values (3, 'Joe Bloggs', 'Sales Manager', 2);

insert into dept values (1, 'Development', 'CA');
insert into dept values (2, 'Sales', 'NY');

alter table emp add (

