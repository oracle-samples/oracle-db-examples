DECLARE
  l_plans_disabled  PLS_INTEGER;
BEGIN
  FOR REC IN (SELECT DISTINCT SQL_HANDLE,PLAN_NAME FROM DBA_SQL_PLAN_BASELINES WHERE sql_text LIKE '%SPMTEST%')
  LOOP
      L_PLANS_DISABLED := DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
        sql_handle => rec.sql_handle,
        plan_name => rec.plan_name,
        attribute_name => 'enabled',
        attribute_value => 'no');
  END LOOP;
END;
/
