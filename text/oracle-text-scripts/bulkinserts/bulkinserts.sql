-- this script compares the timings to insert 100M rows into an indexed table,
-- committing after each row, when SYNC(ON COMMIT) is in use or when the
-- index is set to sync every 1 second.

-- SYNC(ON COMMIT) requires a sync call after each commit operation so can
-- be quite costly

-- if the index is set to 'unusable' the index will be ignored and timings 
-- should be similar to having no index. The index can be rebuilt when the 
-- inserts are finished

set timing on
set echo on

drop table foo;

create table foo (bar varchar2(2000));

-- use SYNC(ON COMMIT)

create index footextindex on foo(bar) indextype is ctxsys.context parameters ('sync(on commit)');

-- alternative: use SYNC(EVERY [1 second])

-- create index footextindex on foo(bar) indextype is ctxsys.context parameters ('sync(every "freq=secondly; interval=1")');


-- comment this and the rebuild out if you want "normal" timings
-- alter index footextindex unusable;

begin
  for i in 1 .. 1000000 loop
    insert into foo values ('the quick brown fox jumps over the lazy dog');
  end loop;
  commit;
end;
/

-- alter index footextindex rebuild;
