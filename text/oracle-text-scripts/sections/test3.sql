exec ctx_thes.drop_thesaurus ('mythes')

host ctxload -user roger/roger -thes -name mythes -file thes.txt

drop table facility;

create table facility (
  facility_id number, 
  name        varchar2(2000)
);

insert into facility values (1, 'Furman University');
insert into facility values (1, 'Furman College');

create index facind on facility(name) indextype is ctxsys.context;

set serveroutput on size 1000000

column name format a30

select * from facility where contains (name, 'college') > 0;
select * from facility where contains (name, 'university') > 0;
select * from facility where contains (name, 'SYN(college, mythes)') > 0;
select * from facility where contains (name, 'SYN(university, mythes)') > 0;

