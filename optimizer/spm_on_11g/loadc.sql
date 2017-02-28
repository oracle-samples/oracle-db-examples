--
-- Create SQL plan baselines from SQL in the shared pool
-- - containing the string "SPM_DEMO"
--
DECLARE
  my_plans pls_integer;
BEGIN
  my_plans := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE(
    attribute_name => 'SQL_TEXT', attribute_value => '%SPM_DEMO%');
END;
/
