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

create table books(id number, info varchar2(100), price number, author varchar2(20), pubdate date);

exec ctx_ddl.create_section_group('mysec', 'basic_section_group')
exec ctx_ddl.add_sdata_column(group_name=>'mysec', section_name=>'datepublished', column_name=>'pubdate')

insert into books values(100, 'Oracle Text <s100>100</s100>', 10000,'Anne Author', '25-Oct-2007');

create index idx on books(info) 
indextype is ctxsys.context 
filter by pubdate
parameters('section group mysec');

-- this will use SDATA if optimizer decides it's appropriate (which it won't for a single row)

select * from books where contains (info, 'oracle') > 0
and pubdate > '01-Jan-2001';

-- this will ONLY work if we've included the "add_sdata_column" call above
-- otherwise we can still use the column name as the SDATA section name

select * from books where contains (info, 'oracle and sdata(datepublished > ''2001-01-01'')') > 0;

