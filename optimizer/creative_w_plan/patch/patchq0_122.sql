@drop
set serveroutput on

declare
   ret varchar2(1024);
begin
   ret := dbms_sqldiag.create_sql_patch(
          sql_id    =>'37090abayamah',
          hint_text =>'FULL(@"SEL$1" "TAB1"@"SEL$1")',    /* Note – VARCHAR2 */
          name      =>'q0_patch');
   dbms_output.put_line(ret);
end;
/
