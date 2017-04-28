--
-- Make a SQL plan baseline for any SQL statement
-- in the cursor cache that has an active SQL profile.
--
declare
  ret varchar2(100);
begin
   for rec in (select sql_id, sql_profile
               from   v$sqlarea
               where  sql_profile is not null 
               and    sql_plan_baseline is null)
   loop
      ret := dbms_spm.load_plans_from_cursor_cache(
                 sql_id=>rec.sql_id,
                 enabled=>'YES');
   end loop;
end;
/
