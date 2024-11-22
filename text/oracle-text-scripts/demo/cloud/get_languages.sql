alter table shoe_reviews add (language varchar2(20));

set serveroutput on
declare 
  outtab ctx_doc.language_tab;
  myclob clob;
begin
  for c in (select rowid, review_text from shoe_reviews) loop
     ctx_doc.policy_languages(
       policy_name => 'SHOE_LX', 
       document    => c.review_text,
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
