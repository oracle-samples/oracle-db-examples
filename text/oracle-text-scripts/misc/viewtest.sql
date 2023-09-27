create table viewtest (id number primary key, text varchar2(20));
insert into viewtest values (1, 'hello world');
create index vti on viewtest (text) indextype is ctxsys.context;
create view viewtest_view as select * from viewtest;
select * from viewtest_view;
select object_name, status from all_objects where object_name like 'VIEWTEST_VIEW';
drop index vti;
select object_name, status from all_objects where object_name like 'VIEWTEST_VIEW';
select * from viewtest_view;
select object_name, status from all_objects where object_name like 'VIEWTEST_VIEW';


