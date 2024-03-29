-- a default json search index in 19c is created with 'SYNC(ON COMMIT)'
-- this can be expensive, especially in a multi-user scenario since only
-- one SYNC can run at once, so commits may queue up

-- changing it to a scheduled background sync is normally recommended.
-- this script shows how to do it without dropping and recreateing the index

drop table foo;

create table foo(bar varchar2(2000) check (bar is json));

insert into foo values ('{ "hello": "world" }');

create search index foobar on foo(bar) for json;

-- output from ctx_report will show we're doing sync(on commit)

set long 50000
set pagesize 0
set linesize 132
set trimspool on
spool index.sql
select ctx_report.create_index_script('foobar') from dual;
spool off

-- do another insert
insert into foo values ('{ "hello": "everyone" }');
-- not searchable until we commit
select * from foo where json_textcontains(bar, '$.hello', 'everyone');
-- now commit and it's searchable

commit;
select * from foo where json_textcontains(bar, '$.hello', 'everyone');


-- now modify the index

alter index foobar parameters ('replace metadata sync (every "freq=secondly;interval=5")');

insert into foo values ('{ "goodbye": "world" }');
commit;
-- won't be searchable immediately
select * from foo where json_textcontains(bar, '$.goodbye', 'world');
-- wait for 5 seconds and retry
exec dbms_session.sleep(5)
select * from foo where json_textcontains(bar, '$.goodbye', 'world');

-- ctx_report will now show sync(every...)
select ctx_report.create_index_script('foobar') from dual;
