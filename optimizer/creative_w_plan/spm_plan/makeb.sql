declare
  ret varchar2(100);
begin
   ret := dbms_spm.load_plans_from_cursor_cache(
                 sql_id=>'2dd6sf2pg9v57',    -- Create baseline for Q1
                 enabled=>'YES');
end;
/
