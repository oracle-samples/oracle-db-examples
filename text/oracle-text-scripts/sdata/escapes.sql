SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
COLUMN INFO FORMAT a60

exec ctx_ddl.drop_section_group('mysec');
drop index idx;
drop table books;

create table books(id number, info varchar2(100));

insert into books values (1, '<title>SEARCH{PATCH}</title> foo');
insert into books values (2, '<title>SEARCH%PATCH}</title> foo');
insert into books values (3, '<title>SEARCH\PATCH}</title> foo');
insert into books values (4, '<title>SEARCHPATCH</title> foo');
insert into books values (5, '<title>SEARCH PATCH</title> foo');

exec ctx_ddl.create_section_group('mysec', 'basic_section_group');
exec ctx_ddl.add_sdata_section('mysec', 'title', 'title', 'VARCHAR2');

create index idx on books(info) indextype is ctxsys.context parameters('section group mysec');


-- should return id=1
select * from books where contains(info, 'foo and SDATA(title like "SEARCH{PATCH}")') > 0;
select * from books where contains(info, 'foo and SDATA(title like "SEARCHPATCH")') > 0;
