--
-- Create SQL plan baselines for SQL statements in cursor cache
-- for the user "SPM_TEST"
--
DECLARE
  my_plans pls_integer;
BEGIN
  my_plans := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE(
    attribute_name => 'SQL_TEXT'
   ,attribute_value => '%MYSPMTEST%');
END;
/
