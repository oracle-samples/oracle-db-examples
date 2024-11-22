drop table neartest;
create table neartest (pk number primary key, text varchar2(2000));

insert into neartest values (1, 'I work for Oracle Corporation');
insert into neartest values (2, 'The Corporation of London uses software purchased from many companies including Microsoft, Oracle and IBM.');
insert into neartest values (3, 'The Corporation of London uses software purchased from many companies including Microsoft, Sybase, Oracle and IBM.');


commit;

create index neartestindex on neartest(text) indextype is ctxsys.context;

column score(1) format 99999
column text format a70

select score(1), text from neartest 
where contains (text, 'near((oracle, corporation))', 1)>0;

