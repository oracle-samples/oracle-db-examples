REM
REM Identify "top SQL" where a SQL plan baseline exists
REM but it is not active. 
REM
REM This might not be intentional!
REM 

SELECT sql_text,
       cpu_time,
       buffer_gets,
       executions,
       parsing_schema_name,
       exact_matching_signature
FROM   v$sql v
WHERE  executions>0
AND    sql_plan_baseline IS NULL
AND    parsing_schema_name != 'SYS'
AND    EXISTS (SELECT 1
               FROM   dba_sql_plan_baselines
               WHERE  signature = v.exact_matching_signature)
AND    NOT EXISTS (SELECT 1
                   FROM   dba_sql_plan_baselines
                   WHERE  signature = v.exact_matching_signature
                   AND    accepted  = 'YES'
                   AND    enabled   = 'YES')
ORDER BY cpu_time;

