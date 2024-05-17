drop table mytable;

create table mytable (text varchar2(20));

insert into mytable values ('XXX');
insert into mytable values ('XXXY');

create index myindex on mytable(text)
indextype is ctxsys.context;

SELECT rowid, text, score(1),
       ( CASE WHEN score(1) > 50 THEN 'Exact' ELSE 'Fuzzy' END )
FROM mytable WHERE CONTAINS (text, '
<query>
   <textquery>
     <progression>
       <seq>XXX</seq>
       <seq>fuzzy((XXX))</seq>
     </progression>
  </textquery>
</query>', 1) > 0
ORDER BY score(1) DESC;
