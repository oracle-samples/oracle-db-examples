declare
  counter number := 1;
begin
  while (counter < 5000 ) loop
    insert into t values ('a'||to_char(counter)||' b'||to_char(counter)||' c'||to_char(counter)||' d'||to_char(counter)||' e'||to_char(counter)||' f'||to_char(counter)||' g'||to_char(counter));
    counter := counter + 1;
  end loop;
end;
