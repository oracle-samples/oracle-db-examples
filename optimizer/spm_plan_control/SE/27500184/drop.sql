--
-- Drop existing SQL plan baselines (with HELLO in the text)
--
declare
  l_plans_dropped  pls_integer;
BEGIN
  for rec in (select distinct sql_handle from dba_sql_plan_baselines where sql_text like '%HELLO%' and creator = user)
  loop
      l_plans_dropped := dbms_spm.drop_sql_plan_baseline (
        sql_handle => rec.sql_handle,
        plan_name  => null);
  end loop;
end;
/
