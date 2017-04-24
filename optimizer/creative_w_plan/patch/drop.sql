
begin
   dbms_sqldiag.drop_sql_patch('q0_patch');
exception
   when others then null;
end;
/

begin
   dbms_sqldiag.drop_sql_patch('q1_patch');
exception
   when others then null;
end;
/

begin
   dbms_sqldiag.drop_sql_patch('q2_patch');
exception
   when others then null;
end;
/

