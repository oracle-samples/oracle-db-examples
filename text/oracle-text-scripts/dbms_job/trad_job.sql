-- example of dbms_job

set echo on
set serverout on

drop table job_log;

create table job_log (insert_date date, text varchar2(2000));

create or replace procedure my_procedure (text varchar2) is
begin
  insert into job_log values (sysdate, text);
  commit;
end;
/
show err

declare
  my_job number;
begin
  dbms_job.submit(
    job => my_job, 
    what => 'my_procedure(''foo'');',
    interval => 'sysdate+(1/24/60)');
  dbms_output.put_line('Job: '||my_job);
end;
/
