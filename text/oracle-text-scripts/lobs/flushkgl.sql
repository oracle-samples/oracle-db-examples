set echo on

create or replace procedure flushkglcache as
  idxid number;

begin
   select idx_id into idxid from ctxsys.dr$index where idx_name = 'WLF_LI_F_TL_CTX1';
   ctxsys.drixmd.PurgeKGL(idxid, 'FUSION', 'WLF_LI_F_TL_CTX1');
end;
/

-- drop job if it exists
begin
  dbms_scheduler.drop_job('FLUSH_KGL_CACHE_FOR_INDEX');
end;
/

begin
  dbms_scheduler.create_job (
    job_name        => 'FLUSH_KGL_CACHE_FOR_INDEX',
    job_type        => 'plsql_block',
    job_action      => 'begin flushkglcache; end;',
    start_date      => systimestamp,
    repeat_interval => 'FREQ=minutely; INTERVAL=1',
    enabled         => TRUE);
end;
/

select owner, job_name, enabled FROM dba_scheduler_jobs
where job_name = 'FLUSH_KGL_CACHE_FOR_INDEX';
