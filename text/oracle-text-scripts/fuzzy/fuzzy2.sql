create table suggestions_table
  (searchterms  varchar2 (30),
   suggestions  varchar2 (20))
/

insert all
into suggestions_table values ('woman', null)
into suggestions_table values ('women', null)
into suggestions_table values ('tomato', null)
into suggestions_table values ('tomatoes', null)
select * from dual
/

create index your_index
on suggestions_table (searchterms)
indextype is ctxsys.context
/

create or replace procedure test_proc
 (p_searchphrase	in varchar2)
as
  v_searchword    varchar2 (100);
begin
   for x in 1 .. 6 loop
       v_searchword := listgetat(regexp_replace(p_searchphrase,',',' '),x,' ');
       for c1 in (select * from
                      (select score(1) as score, searchterms, suggestions from suggestions_table
                       where contains(searchterms,'fuzzy({'||v_searchword||'},,,weight)',1)>0
                       -- check if xth word exists:
                       AND   V_SEARCHWORD IS NOT NULL
                       order by score desc)
                   where rownum < 10) loop
          dbms_output.put_line
            (lpad (c1.score, 3) || ' ' ||
             rpad (c1.searchterms, 30) || ' ' ||
             v_searchword);
        end loop;
   end loop;
end test_proc;
/ 
