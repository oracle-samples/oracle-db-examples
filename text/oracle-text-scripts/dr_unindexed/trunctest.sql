-- user running this script must have been granted select on
-- ctxsys.dr$unindexed

set echo on

drop table foo;

create table foo (bar varchar2(2000));

insert into foo values ('hello world');

create index fooindex on foo(bar) indextype is ctxsys.context
parameters ('transactional');

prompt Press Enter to insert record...
pause

insert into foo values ('goodbye world');

select count(*) from ctxsys.dr$unindexed;

select * from foo where contains(bar, 'goodbye') > 0;

prompt Press Enter to commit...
pause

commit;

select count(*) from ctxsys.dr$unindexed;

select * from foo where contains(bar, 'goodbye') > 0;

prompt Press Enter to sync...
pause

exec ctx_ddl.sync_index ('fooindex')

select count(*) from ctxsys.dr$unindexed;
