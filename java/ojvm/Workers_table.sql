rem
rem Workers.sql
rem
connect hr/hr@pdb1

rem
rem Set up the Workers table
rem

drop table workers;
create table workers (wid int, wname varchar2(20), 
     wposition varchar2(25), wsalary int);

insert into workers values (103, 'Adams Tagnon', 'Janitor', 10000);
insert into workers values (201, 'John Doe', 'Secretary', 20000);
insert into workers values (323, 'Racine Johnson', 'Junior Staff Member', 30000);
insert into workers values (418, 'Abraham Wilson', 'Senior Staff Member', 40000);
insert into workers values (521, 'Jesus Nucci', 'Engineer', 50000);
insert into workers values (621, 'Jean Francois', 'Engineer', 60000);
commit;
