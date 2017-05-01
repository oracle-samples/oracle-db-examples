declare
  cnt pls_integer;
begin
  cnt:=dbms_spm.load_plans_from_cursor_cache(
       sql_id =>          '4s5bm2bgy0g0v',          -- Q2
       plan_hash_value => :phv,
       sql_handle =>      'SQL_b57b065c950a54a8');  -- Plan baseline for Q1
end;
/
