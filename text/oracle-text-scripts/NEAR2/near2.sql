set echo off
drop table near2test;
create table near2test (text varchar2(2000));

insert into near2test values ('the quick brown fox jumps over the lazy dog');
insert into near2test values ('the quick brown fox jumped over the lazy dog');
insert into near2test values ('the lazy dog jumps over the quick brown fox');
insert into near2test values ('the lazy fox jumps over the quick brown dog');
insert into near2test values ('the advaark and the quick brown fox jumps over the lazy dog');
insert into near2test values ('the lazy dog runs along and jumps over the quick brown fox');
insert into near2test values ('the lazy green fox jumps over the quick brown dog');
insert into near2test values ('the quick gray brown male fox runs and jumps over the lazy dog');
insert into near2test values ('the quick brown male fox runs and jumps over the lazy dog');
insert into near2test values ('the quick brown fox runs and jumps over the lazy dog');
insert into near2test values ('the brown fox runs and jumps over the quick lazy dog');
insert into near2test values ('the lazy fox jumps over the quick brown fox who jumps');

create index near2testindex on near2test(text) indextype is ctxsys.context;

set lines 200 
column text format a80

set echo on
select score(1), text from near2test where contains( text, '?(near2((quick,broon,fox,jumps)))', 1) > 0
order by score(1) desc;
