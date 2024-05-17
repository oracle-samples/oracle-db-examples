drop table checktab;
create table checktab (val varchar2(20), ins_time date);

create or replace procedure testproc as
begin
   insert into checktab values (1, sysdate);
   commit;
end;
/

begin
   dbms_scheduler.drop_job (
      job_name   => 'testjob' );
end;
/

begin
   dbms_scheduler.create_job (
      job_name   => 'testjob',
      job_type   => 'PLSQL_BLOCK',
      job_action => 'begin testproc; end;',
      enabled    => FALSE );
end;
/

exec dbms_lock.sleep(2)

select * from checktab;

begin
   dbms_scheduler.run_job (
     job_name => 'testjob' );
end;
/

exec dbms_lock.sleep(2)

select * from checktab;

begin
   dbms_scheduler.run_job (
     job_name => 'testjob' );
end;
/

exec dbms_lock.sleep(2)

select * from checktab;


