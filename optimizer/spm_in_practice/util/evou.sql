REM
REM Query SQL plan history for evolve candidates
REM for a specified user
REM

SELECT sql_text, 
       signature, 
       sql_handle, 
       plan_name
FROM   dba_sql_plan_baselines
WHERE  enabled  = 'YES'
AND    accepted = 'NO'
AND    parsing_schema_name = UPPER('&1')
AND    last_verified IS NULL;
