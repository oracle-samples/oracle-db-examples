drop table mytable;

create table mytable (numcol number, text varchar2(200));

insert into mytable
   select 10, 'the quick brown fox jumps over the lazy dog' from dual
union
   select 20, 'the quick brown fox jumps over the lazy fox' from dual
union
   select 30, 'a lazy brown fox jumps quickly' from dual;

create index myindex on mytable(text) indextype is ctxsys.context;

select token_text from dr$myindex$i;

-- 

select * from mytable

select * from mytable where contains (text, 'quick') > 0;

column text format a60

select * from mytable 
  where numcol < 20
  and   contains (text, 'quick') > 0;

select score(99), text from mytable
  where contains (text, 'fox', 99) > 0
  order by score(99) desc;

select * from mytable 
  where contains ( text, 'quick or quickly' ) > 0;

select * from mytable 
  where contains ( text, 'quick%' ) > 0;

select * from mytable 
  where contains ( text, 'lazy fox' ) > 0;

--

insert into mytable values (40, 'brown cat');

select * from mytable 
  where contains (text, 'cat') > 0;

exec ctx_ddl.sync_index ('myindex')

select * from mytable 
  where contains (text, 'cat') > 0;

select token_text from dr$myindex$i;

exec ctx_ddl.optimize_index('myindex', 'FULL')

select token_text from dr$myindex$i;

drop index myindex;

create index myindex on mytable(text) indextype is ctxsys.context
parameters ('sync (on commit)');

insert into mytable values (50, 'brown rabbit');

select * from mytable 
  where contains (text, 'rabbit') > 0;

commit;

select * from mytable 
  where contains (text, 'rabbit') > 0;

drop index myindex;

create index myindex on mytable(text) indextype is ctxsys.context
parameters ('sync (every "freq=secondly; interval=5")');


