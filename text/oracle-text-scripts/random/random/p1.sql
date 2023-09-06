select /*+ first_rows(10) */ score, id from 
(  select /*+ DOMAIN_INDEX_SORT */ score(1) as score, id
   from docs 
   where contains (text, 'bo and ba', 1) > 0
   and id < 1000000
   order by score(1) desc
) where rownum <= 10
/
