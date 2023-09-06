drop table mytest;

create table mytest (text varchar2(30));
insert into mytest values ('cat cat');
insert into mytest values ('cat dog dog');
insert into mytest values ('cat cat cat dog dog dog');
create index mytestind on mytest(text) indextype is ctxsys.context;

select text, score(1) from mytest where contains (text, 
'<query><textquery>cat</textquery><score algorithm="count"/></query>',1)>0;

select text, score(1) from mytest where contains (text, 
'<query><textquery>cat or dog</textquery><score algorithm="count"/></query>',1)>0;

select text, score(1) from mytest where contains (text, 
'<query><textquery>cat, dog</textquery><score algorithm="count"/></query>',1)>0;

