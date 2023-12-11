-- working example

-- clean up first - some of this will fail first time

delete from user_scheduler_job_run_details where job_name = 'ECHO_JOB';

exec dbms_scheduler.drop_job('echo_job')
exec dbms_scheduler.drop_credential('MYCRED')

-- create credentials

exec dbms_scheduler.create_credential('MYCRED', '&&username', '&&password');

-- create job

BEGIN
 DBMS_SCHEDULER.CREATE_JOB(
   job_name             => 'ECHO_JOB',
   job_type             => 'EXECUTABLE',
   number_of_arguments  => 3,
   job_action           => '\windows\system32\cmd.exe',
   credential_name      => 'mycred',
   auto_drop            => FALSE);

 DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE('echo_job',1,'/c');
 DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE('echo_job',2,'echo');
 DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE('echo_job',3,'helloworld');
 DBMS_SCHEDULER.ENABLE('ECHO_JOB');
END;
/

prompt Waiting 2 seconds...
exec dbms_lock.sleep(2)

select output from user_scheduler_job_run_details where job_name = 'ECHO_JOB';

select dump(binary_output) from 

variable outtext varchar2(4000);

declare
  buff  raw(4000);
  vblob blob;
  amt   number := 4000;
begin
  select binary_output into vblob from user_scheduler_job_run_details where job_name = 'ECHO_JOB';
  dbms_lob.read( vblob, amt, 1, buff );
  select dump( buff ) into :outtext from dual;
end;
/


-- NON-working example : this fails because directory does not exist

-- clean up first - some of this will fail first time

delete from user_scheduler_job_run_details where job_name = 'ECHO_JOB';

exec dbms_scheduler.drop_job('echo_job')
exec dbms_scheduler.drop_credential('MYCRED')

-- create credentials

exec dbms_scheduler.create_credential('MYCRED', '&&username', '&&password');

print outtext

-- create job

BEGIN
 DBMS_SCHEDULER.CREATE_JOB(
   job_name             => 'ECHO_JOB',
   job_type             => 'EXECUTABLE',
   number_of_arguments  => 3,
   job_action           => '\AAAA\system32\cmd.exe',
   credential_name      => 'mycred',
   auto_drop            => FALSE);

 DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE('echo_job',1,'/c');
 DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE('echo_job',2,'echo');
 DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE('echo_job',3,'helloworld');
 DBMS_SCHEDULER.ENABLE('ECHO_JOB');
END;
/

prompt Waiting 2 seconds...
exec dbms_lock.sleep(2)

select output from user_scheduler_job_run_details where job_name = 'ECHO_JOB';

select dump(binary_output) from 

variable outtext varchar2(4000);
variable errtext varchar2(4000);

declare
  buff  raw(4000);
  vblob blob;
  amt   number := 4000;
begin
  select binary_output into vblob from USER_SCHEDULER_JOB_RUN_DETAILS where job_name = 'ECHO_JOB';
  if length( vblob ) > 0 then 
     dbms_lob.read( vblob, amt, 1, buff );
     select dump( buff ) into :outtext from dual;
  end if;

  select binary_errors into vblob from user_scheduler_job_run_details where job_name = 'ECHO_JOB';
  if length( vblob ) > 0 then 
    dbms_lob.read( vblob, amt, 1, buff );
    select dump( buff ) into :errtext from dual;
  end if;
end;
/

print outtext

print errtext
