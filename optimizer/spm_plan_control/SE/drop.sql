DECLARE
  l_plans_dropped  PLS_INTEGER;
BEGIN

  FOR REC IN (SELECT DISTINCT sql_handle FROM dba_sql_plan_baselines WHERE creator = USER)
  LOOP
      l_plans_dropped := DBMS_SPM.DROP_SQL_PLAN_BASELINE (
        sql_handle => rec.sql_handle,
        plan_name  => NULL);
  END LOOP;

END;
/

