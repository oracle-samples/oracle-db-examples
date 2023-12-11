set serveroutput on
declare 
  outtab ctx_doc.theme_tab;
  myclob clob;
begin
  for c in (select rowid, filename from docs) loop
     dbms_output.put_line(chr(10)||'Filename : '||c.filename||' Top 10 themes:');
     ctx_doc.themes(
       index_name  => 'DOCSINDEX', 
       textkey     => to_char(c.rowid),
       restab      => outtab, 
       num_themes  => 10);
     for x in (select theme, weight 
                from table(outtab)
                order by weight desc
                fetch next 10 rows only ) loop
       dbms_output.put_line(x.theme||' ('||x.weight||'%)');
     end loop;
   end loop;
end;
/
