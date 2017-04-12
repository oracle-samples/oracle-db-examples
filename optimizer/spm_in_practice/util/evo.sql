REM
REM Query SQL plan history for evolve candidates
REM

SELECT sql_text, 
       signature, 
       sql_handle, 
       plan_name
FROM   dba_sql_plan_baselines
WHERE  enabled  = 'YES'
AND    accepted = 'NO'
AND    last_verified is NULL;
