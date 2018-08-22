-- disable and stop all the jobs
@cadm

declare
  res integer;
begin 
  for rec in (select job_name, state, owner
                from dba_scheduler_jobs
                where enabled = 'TRUE') loop
    dbms_scheduler.disable(rec.owner || '.' || rec.job_name, true);
    if (rec.state = 'RUNNING') then
      begin
        dbms_scheduler.stop_job(rec.owner || '.' || rec.job_name, true);
      exception when others then
        -- ignore [job "..." is not running] error just in case
        if (sqlcode != -27366) then
          raise;
        end if;
      end;
    end if;
  end loop;
  dbms_lock.sleep(30);

  select count(*) into res
    from dba_scheduler_jobs
    where state = 'RUNNING' or enabled = 'TRUE';

  if (res != 0) then
    raise_application_error(-20000,
      'ERROR: The Scheduler FAILED to disable or stop some jobs');
  end if;
end;
/
