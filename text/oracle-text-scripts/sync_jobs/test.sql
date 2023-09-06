connect / as sysdba

drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,ctxapp, create job to testuser;


connect testuser/testuser

create table foo (bar varchar2(200));

create index fooindex on foo(bar) indextype is ctxsys.context
parameters( 'sync (manual)');

-- check behavior with a without this next line
-- connect / as sysdba

alter index testuser.fooindex rebuild 
parameters( 'replace metadata sync (every sysdate+1/24/60)' );

column job_name format a30
column job_creator format a30

select job_name, job_creator from all_scheduler_jobs where job_name like 'DR$FOOINDEX%';

