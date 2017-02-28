--
-- DISCLAIMER:
-- This script is provided for educational purposes only. It is 
-- NOT supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts initially 
-- on a test instance.
--
-- Script Vesion 0.1 - TEST
--
--
select name AS "Consumer Group"
      ,ROUND(DECODE(sum(PQS_COMPLETED),0,0,
             sum(PQ_QUEUED_TIME)/1000/sum(PQS_COMPLETED)),2) 
                                      AS "Total Q Time Per Prl Exec"
      ,ROUND(DECODE(sum(PQS_COMPLETED),0,0,
             sum(PQS_QUEUED)/sum(PQS_COMPLETED))*100,2)
                                      AS "Percent Prl Stmts Queued"
      ,SUM(CURRENT_PQS_QUEUED)        AS "Current Prl Stmts Queued"
      ,SUM(CURRENT_PQS_ACTIVE)        AS "Current Prl Stmts Active"
      ,SUM(CURRENT_PQ_SERVERS_ACTIVE) AS "Current PX Servers Active"
      ,SUM(IDLE_SESSIONS_KILLED)      AS "Sesions Killed"
      ,SUM(SQL_CANCELED)              AS "SQL Cancelled"
from  gv$rsrc_consumer_group
group by name
order by name;

SELECT TO_CHAR(ROUND(begin_time,'MI'), 'HH:MI') AS "Time"
      ,consumer_group_name                      AS "Consumer Group"
      ,SUM(AVG_ACTIVE_PARALLEL_STMTS)           AS "Ave Active Parallel Stmts"
      ,SUM(AVG_QUEUED_PARALLEL_STMTS)           AS "Ave Queued"
      ,SUM(AVG_ACTIVE_PARALLEL_SERVERS)         AS "Ave Active"
FROM  gv$rsrcmgrmetric_history
GROUP BY ROUND(begin_time,'MI'),
         consumer_group_name
ORDER BY ROUND(begin_time,'MI'),
         consumer_group_name;
 
SELECT  TO_CHAR(ROUND(begin_time,'MI'), 'HH:MI') 
                                     AS "Time"
        ,consumer_group_name         AS "Consumer Group"
        ,ROUND(sum(CPU_CONSUMED_TIME) / 60000,2) 
                                     AS "Average Num Running Sessions"
        ,ROUND(sum(cpu_wait_time) / 60000,2) 
                                     AS "Average Num Waiting Sessions"
FROM     gv$rsrcmgrmetric_history
GROUP BY ROUND(begin_time,'MI'),
         consumer_group_name
ORDER BY  ROUND(begin_time,'MI')
         ,consumer_group_name;

SELECT  req_degree||' -> '||degree     AS "Requested DOP -> Actual DOP"
       ,count(distinct qcsid)          AS "Number Executing"
FROM   gv$px_session
WHERE  req_degree IS NOT NULL
GROUP BY req_degree||'->'||degree;


SELECT  name
              ,value
FROM   gv$sysstat 
WHERE  UPPER (name) LIKE '%PARALLEL OPERATIONS%'
ORDER BY name;


SELECT  inst_id
       ,sql_text
       ,username
       ,status
       ,px_servers_requested
       ,px_servers_allocated
FROM   gv$sql_monitor
ORDER BY last_refresh_time;

select  inst_id iid
       ,count(*) n
from  gv$pq_slave
where status = 'BUSY'
group by inst_id
order by 1;
 
select qksxareasons
      ,indx 
FROM  x$qksxa_reason
WHERE QKSXAREASONS LIKE '%DOP downgrade%';

