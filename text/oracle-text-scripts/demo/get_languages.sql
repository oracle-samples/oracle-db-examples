set serveroutput on
declare 
  outtab ctx_doc.language_tab;
  myclob clob;
begin
  for c in (select rowid, filename from docs) loop
     dbms_output.put_line('Checking file: '||c.filename);
     ctx_doc.filter(
       index_name  => 'DOCSINDEX', 
       textkey     => to_char(c.rowid),
       restab      => myclob,
       plaintext   => TRUE );
     ctx_doc.policy_languages(
       policy_name => 'DEFAULT_POLICY', 
       document    => myclob,
       restab      => outtab );
     for x in (select language, score 
                from table(outtab)
                order by score desc
                fetch next 1 rows only ) loop
       dbms_output.put_line('language: '||x.language||' score: '||x.score);
     end loop;
   end loop;
end;
/
