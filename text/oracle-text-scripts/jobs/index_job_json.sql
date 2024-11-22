-- This script demonstrates how to replace the standard DBMS_SCHEDULER job which syncs 
-- text or JSON indexes with a lightweight IN_MEMORY job which only produces logging 
-- data if it fails.

set echo on

connect / as sysdba

-- create a demo user
grant connect,resource,ctxapp, unlimited tablespace to demouser identified by demouser;

-- must be able to create jobs
grant create job to demouser;

-- needs this access to create in-memory jobs
grant execute on sys.default_in_memory_job_class to demouser;

-- this is just for this script
grant execute on dbms_lock to demouser;

connect demouser/demouser

-- drop table if it already exists
drop table mytable;

-- a simple table
create table mytable(text varchar2(200), constraint mycheckjson check(text is json));

-- index that syncs automatically every second
create search index myindex on mytable(text) for json
parameters ('sync (every "freq=secondly;interval=1")');

-- Now we want to check the logs produced

connect / as sysdba

select count(*) "Event Log" from scheduler$_event_log
where name = 'DR$MYINDEX$J'
and  owner = 'DEMOUSER';

select count(*) "Run Details" from scheduler$_job_run_details
where log_id in 
  (select log_id from scheduler$_event_log
   where name = 'DR$MYINDEX$J'
   and  owner = 'DEMOUSER' );

-- wait two seconds and check the count again - should increase
prompt Sleep 2
exec dbms_lock.sleep(2)

select count(*) "Event Log" from scheduler$_event_log
where name = 'DR$MYINDEX$J'
and owner = 'DEMOUSER';

select count(*) "Run Details" from scheduler$_job_run_details
where log_id in 
  (select log_id from scheduler$_event_log
   where name = 'DR$MYINDEX$J'
   and  owner = 'DEMOUSER' );

-- Now we'll turn off automatic sync and create our own job to do the syncing

connect demouser/demouser

-- this does NOT do a full index rebuild
alter index myindex rebuild online parameters ('replace metadata sync(manual)');

-- The standard job is called DR$<indexname>$J
-- rather than the above alter index, we could have deleted the standard job and
-- replaced it with our own. That would have the advantage that when the index is
-- dropped, the job will be dropped with it. But since the creation of jobs may 
-- change between versions, it is safer to turn off the automatic sync and create
-- our own job.

-- The disadvantage of creating our own job is that we must track it ourselves,
-- and drop the job manually if the index is dropped.

-- For example if you use the same job name (as I have below) then if you try to 
-- drop and create the index with SYNC(EVERY...) then the index creation will fail
-- saying the job already exists

prompt Creating lightweight job

-- delete if it already exists
begin
  dbms_scheduler.drop_program ('mysync');
  exception when others then null;
end;
/

begin
  dbms_scheduler.create_program (
    program_name    => 'mysync',
    program_type    => 'PLSQL_BLOCK',
    program_action  => 'BEGIN ctx_ddl.sync_index(''myindex''); END;',
    enabled         => TRUE );
end;
/

-- delete if it already exists
begin
  dbms_scheduler.drop_job ('DR$MYINDEX$J');
  exception when others then null;
end;
/

begin
  dbms_scheduler.create_job (
    job_name        => 'DR$MYINDEX$J',
    program_name    => 'mysync',
    start_date      => systimestamp,
    repeat_interval => 'freq=secondly; interval=1',
    job_style       => 'IN_MEMORY_RUNTIME',
    enabled         => true );
end;
/

-- Now check that no more log records are being produced:
connect / as sysdba

select count(*) "Event Log" from scheduler$_event_log
where name = 'DR$MYINDEX$J'
and owner = 'DEMOUSER';

select count(*) "Run Details" from scheduler$_job_run_details
where log_id in 
  (select log_id from scheduler$_event_log
   where name = 'DR$MYINDEX$J'
   and  owner = 'DEMOUSER' );

prompt Sleep 2
exec dbms_lock.sleep(2)

select count(*) "Event Log" from scheduler$_event_log
where name = 'DR$MYINDEX$J'
and owner = 'DEMOUSER';

select count(*) "Run Details" from scheduler$_job_run_details
where log_id in 
  (select log_id from scheduler$_event_log
   where name = 'DR$MYINDEX$J'
   and  owner = 'DEMOUSER' );

-- Make sure DML still works OK

connect demouser/demouser

insert into mytable values ('{ "data": "foo bar" }');
commit;

exec dbms_lock.sleep(2)

-- run a query
select * from mytable where json_textcontains (text, '$.*', 'bar');

-- for the purpose of this script ONLY, clean up the job 
--  (otherwise index creation will fail if script is re-run)
exec dbms_scheduler.drop_job ('DR$MYINDEX$J')
