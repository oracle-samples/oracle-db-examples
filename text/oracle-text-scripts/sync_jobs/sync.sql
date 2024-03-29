set timing on
set echo on

connect testuser/testuser

declare
  str clob;
begin
  -- 10 rows, ids 100 apart
  for k in 1 .. 10 loop
    str := ' ';
    -- 400 words per row
    for i in 1..400 loop
      str := str || ' word' || to_char(i*100);
    end loop;
    insert into test values (k, str);
    commit;
  end loop;
end;
/

exec ctx_ddl.sync_index(idx_name => 'testindex', parallel_degree => 2)

quit

