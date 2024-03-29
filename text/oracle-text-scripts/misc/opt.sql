declare 
   max_rows number := 1000;
   counter number := 0;
begin
   for c in ( select token_text, count(*) cntr from dr$fooindex$i
              group by token_text
              order by cntr desc ) loop
      ctx_ddl.optimize_index('fooindex', 'TOKEN', null, c.token_text, null, 16);
      counter := counter + 1;
      exit when counter > max_rows;
   end loop;
end;
/
