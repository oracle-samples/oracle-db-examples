-- example of dbms_job

set echo on
set serverout on

drop table job_log;

create table job_log (insert_date date, text varchar2(2000));

--create or replace procedure my_procedure (text varchar2) is
--begin
--  insert into job_log values (sysdate, text);
--  commit;
--end;
--/
--show err

--declare
--  my_job number;
--begin
--  dbms_job.submit(
--    job => my_job, 
--    what => 'my_procedure(''foo'');',
--    interval => 'sysdate+(1/24/60)');
--  dbms_output.put_line('Job: '||my_job);
-- end;
-- /

drop sequence jobno_sequence;

create sequence jobno_sequence;

create or replace package mydbms_job is

job_prefix constant varchar2(200) := 'MYDBMS$JOB$';

procedure submit (
 JOB				OUT BINARY_INTEGER,
 WHAT				IN  VARCHAR2,
 NEXT_DATE			IN  DATE DEFAULT SYSDATE,
 INTERVAL			IN  VARCHAR2 DEFAULT NULL,
 NO_PARSE			IN  BOOLEAN DEFAULT FALSE,
 INSTANCE			IN  BINARY_INTEGER DEFAULT NULL,
 FORCE				IN  BOOLEAN DEFAULT FALSE
);

end mydbms_job;
/
show err

create or replace package body mydbms_job is

procedure submit (
 JOB				OUT BINARY_INTEGER,
 WHAT				IN  VARCHAR2,
 NEXT_DATE			IN  DATE DEFAULT SYSDATE,
 INTERVAL			IN  VARCHAR2 DEFAULT NULL,
 NO_PARSE			IN  BOOLEAN DEFAULT FALSE,
 INSTANCE			IN  BINARY_INTEGER DEFAULT NULL,
 FORCE				IN  BOOLEAN DEFAULT FALSE
) is
  job_name varchar2(30);
begin
  job := jobno_sequence.nextval;
  job_name := job_prefix || job;

  dbms_scheduler.create_job (
     job_name        => job_name,
     job_type        => 'PLSQL_BLOCK',
     job_action      => what,
     start_date      => next_date,
     repeat_interval => interval,
     enabled         => TRUE,
     comments        => 'DBMS_JOB compatibility layer'
  );

end;

end mydbms_job;
/

create or replace procedure my_procedure (text varchar2) is
begin
  insert into job_log values (sysdate, text);
  commit;
end;
/

declare
  my_job number;
begin
  mydbms_job.submit(
     job => my_job,
     what => 'my_procedure(''mydbms_job'');',
     interval => 'sysdate+(1/24/60)');
     dbms_output.put_line('Job: '||my_job);
end;
/
