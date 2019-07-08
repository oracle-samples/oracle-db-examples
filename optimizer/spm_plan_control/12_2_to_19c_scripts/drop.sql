set echo on
alter system flush shared_pool;

DECLARE
  l_plans_dropped  PLS_INTEGER;
BEGIN
  FOR REC IN (SELECT DISTINCT SQL_HANDLE FROM DBA_SQL_PLAN_BASELINES where sql_text like '%HELLO%')
  LOOP
      L_PLANS_DROPPED := DBMS_SPM.DROP_SQL_PLAN_BASELINE (
        sql_handle => rec.sql_handle,
        PLAN_NAME  => NULL);
  END LOOP;
END;
/

