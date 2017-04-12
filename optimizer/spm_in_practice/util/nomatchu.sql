REM
REM List SQL statements in the cursor cache that are not 
REM matching a SQL plan baseline but a SQL plan baseline exists.
REM
REM You may want to investigate these cases because it implies
REM that there may have been a change preventing the plan in the
REM SQL plan baseline from being used.
REM
REM This query allows you to specify a particular schema.
REM

set linesize 200
set trims on
set tab off
column sql_text format a50
column parsing_schema_name format a30
column exact_matching_signature format 99999999999999999999

SELECT sql_text,
       cpu_time,
       buffer_gets,
       executions,
       parsing_schema_name,
       sql_id,
       exact_matching_signature
FROM   v$sql v
WHERE  executions>0
AND    sql_plan_baseline IS NULL
AND    EXISTS (SELECT 1
               FROM   dba_sql_plan_baselines
               WHERE  signature = v.exact_matching_signature
               AND    accepted = 'YES'
               AND    enabled  = 'YES'
               AND    parsing_schema_name = UPPER('&1'))
ORDER BY cpu_time;
