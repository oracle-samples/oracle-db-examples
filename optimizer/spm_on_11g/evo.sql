set linesize 10000
set trims on

set serveroutput on
DECLARE
 cVal CLOB;
BEGIN
  cVal := dbms_spm.evolve_sql_plan_baseline();
  dbms_output.put_line(cVal);
END;
/

set linesize 250
