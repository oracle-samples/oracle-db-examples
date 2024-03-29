
declare
  fred integer;
  bill number;
begin
  bill := 1.789;
  fred := trunc(bill);
  dbms_output.put_line('fred is '||to_char(fred));
end;
/
