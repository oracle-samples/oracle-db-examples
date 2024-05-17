SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 130
SET TAB OFF
SET PAGESIZE 100

drop index idx;
drop table books;

create table books(id number, info varchar2(100), price number, author varchar2(20), pubdate date);

insert into books values(100, 'Oracle Text <s100>100</s100>', 10000,'Anne Author', '25-Oct-2007');

create index idx on books(info) 
indextype is ctxsys.context 
filter by pubdate;

-- this will use SDATA if optimizer decides it's appropriate (which it may not for a single row)

select /*+ INDEX(books idx) */ * from books where contains (info, 'oracle') > 0
and pubdate > '01-Jan-2001';

-- explain that 

explain plan for 
  select /*+ INDEX(books idx) */ * from books where contains (info, 'oracle') > 0
  and pubdate > '01-Jan-2001';

set echo off
@?/rdbms/admin/utlxpls
