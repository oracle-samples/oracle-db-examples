--
-- Load baselinese from a SQL Tuning Set
--
DECLARE
my_plans pls_integer;
BEGIN
  my_plans := DBMS_SPM.LOAD_PLANS_FROM_SQLSET('my_workload');
END;
/
