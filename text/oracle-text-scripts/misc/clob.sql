declare
  c1 clob := '';
  c2 clob := '';
begin
  for i in 1..5000 loop
    c1 := c1 || 'x';
  end loop;
  c2 := 'y';
  c2 := c2 || c1;
end;
/
