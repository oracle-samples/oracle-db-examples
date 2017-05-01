--
-- Disable all SQL Profiles where the SQL statement
-- is able to use a SQL plan baseline instead.
--
begin
   for rec in (select sql_profile
               from   v$sqlarea
               where  sql_profile       is not null
               and    sql_plan_baseline is not null)
   loop
      dbms_sqltune.alter_sql_profile(
                             name=>rec.sql_profile,
                             attribute_name=>'STATUS', 
                             value=>'DISABLED');
   end loop;
end;
/
