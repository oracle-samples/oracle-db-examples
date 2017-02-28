DECLARE
my_plans pls_integer;
BEGIN
  my_plans := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE(
    attribute_name => 'sql_text',
    attribute_value => '%SPM%');
END;
/
