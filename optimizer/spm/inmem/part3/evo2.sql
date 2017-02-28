set serveroutput on
DECLARE
 cVal CLOB;
BEGIN
  cVal := dbms_spm.evolve_sql_plan_baseline(sql_handle=>'&sql_handle',verify=>'NO');
  dbms_output.put_line(cVal);
END;
/
set serveroutput off
