@drop

declare
   pname varchar2(100);
begin
   pname := dbms_sqldiag.create_sql_patch(
      sql_id    =>'bdrzvmxvcju4y',
      hint_text =>'IGNORE_OPTIM_EMBEDDED_HINTS', 
      name      =>'q1_patch');
end;
/
