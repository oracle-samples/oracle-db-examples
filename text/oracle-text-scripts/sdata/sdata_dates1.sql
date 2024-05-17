SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

exec ctx_ddl.drop_section_group('mysec');
drop index idx;
drop table books;

create table books(id number, info varchar2(100), price number, author varchar2(20));

exec ctx_ddl.create_section_group('mysec', 'basic_section_group')
exec ctx_ddl.add_sdata_section(group_name=>'mysec', section_name=>'datepublished', tag=>'pubdate', datatype=>'DATE')

insert into books values(100, 'Oracle Text <pubdate>2010-01-01</pubdate>', 10000, 'Anne Author');

create index idx on books(info) 
indextype is ctxsys.context 
parameters('section group mysec');

-- search using sdata

select * from books where contains (info, 'oracle and sdata(datepublished > ''2001-01-01'')') > 0;

