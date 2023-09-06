begin
  for i in 1..50000 loop
    insert into t values (i);
  end loop;
end;
/
