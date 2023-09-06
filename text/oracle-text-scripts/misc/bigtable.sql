set timing on

create table bigtable (id number, title varchar2(4000), created date, length number);

insert into bigtable values (1, 'the quick brown fox jumps over the lazy dog', sysdate, 1);

insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;
insert into bigtable select * from bigtable;

update bigtable set id=rownum;

create index bigtable_id on bigtable(id);

update bigtable set length=trunc(dbms_random.value(0,100000)) where id < 100000;

create index bigtable_length on bigtable (length);

create index title_index on bigtable (title) indextype is ctxsys.context;

create index length_index on bigtable (length);

create index title_index on bigtable (title) indextype is ctxsys.context

create table bigtable2 as select * from bigtable unrecoverable;

select count(*) from bigtable where contains (title, 'fox') > 0
and length=12345;

create index title_index2 on bigtable2 (title) indextype is ctxsys.context
filter by length
order by length;

select count(*) from bigtable where contains (title, 'fox') > 0
and length=9991;

select count(*) from bigtable2 where contains (title, 'fox') > 0
and length=9991;
