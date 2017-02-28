REM
REM  Identify "top SQL" not using a SQL plan baseline.
REM  You may wish to modify to focus on other metrics like
REM  executions or IO.
REM

SELECT sql_text,
       cpu_time,
       buffer_gets,
       executions,
       parsing_schema_name,
       sql_id,
       exact_matching_signature
FROM   v$sql
WHERE  sql_plan_baseline IS NULL
AND    executions>0
AND    parsing_schema_name != 'SYS'
ORDER BY cpu_time;

