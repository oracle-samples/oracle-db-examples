--
-- List scheduler information
--
set pagesize 1000
col job_name FOR a30
set trims on
set linesize 300
set tab off
column window_name format a70
column operation format a60
column attributes format a70;
column client_name format a40;
column operation_name format a30;
column JOB_START_TIME format a40
column job_duration format a15
column job_info format a70
column job_status format a10
column owner format a15
column job_class format a30

select JOB_STATUS,JOB_START_TIME,JOB_DURATION,job_info
from DBA_AUTOTASK_JOB_HISTORY 
where JOB_START_TIME > systimestamp - 1 
and   client_name='auto optimizer stats collection'
order by job_start_time desc ;

select * from (
select operation||decode(target,null,null,'-'||target) operation
      ,to_char(start_time,'YYMMDD HH24:MI:SS.FF4') start_time
      ,to_char(  end_time,'YYMMDD HH24:MI:SS.FF4') end_time
from dba_optstat_operations
order by start_time desc)
where rownum<20
/


select client_name, status
from dba_autotask_client
where client_name in ( 'auto space advisor', 'auto optimizer stats collection','sql tuning advisor');

SELECT CLIENT_NAME,WINDOW_GROUP FROM DBA_AUTOTASK_CLIENT;

select WINDOW_NAME,OPTIMIZER_STATS,SEGMENT_ADVISOR,SQL_TUNE_ADVISOR,WINDOW_NEXT_TIME from DBA_AUTOTASK_WINDOW_CLIENTS;


column window_name format a20
column window_start_time format a40
column window_duration format a35
column window_end_time format a40
select * from dba_autotask_client_history order by WINDOW_START_TIME desc;


column last_change format a20
select * from dba_autotask_operation;

column last_good_date format a40
select TASK_NAME,STATUS,LAST_GOOD_DATE,LAST_GOOD_DURATION,LAST_TRY_RESULT,LAST_TRY_DURATION from dba_autotask_task
where client_name = 'auto optimizer stats collection';

select job_name, state, owner, job_class
from dba_scheduler_jobs
where enabled = 'TRUE';
