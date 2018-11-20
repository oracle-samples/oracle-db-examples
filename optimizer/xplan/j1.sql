select sum(a.id), sum(b.id),
       sum(c.id), sum(d.id), sum(e.id)
from   table_10          a
       join table_100    b on (a.id = b.fkcol)
       join table_1000   c on (b.id = c.fkcol)
       join table_10000  d on (c.id = d.fkcol)
       join table_100000 e on (d.id = e.fkcol);

@@typ

pause Press <cr> to continue 

select /*+ gather_plan_statistics */ 
       sum(a.id), sum(b.id),
       sum(c.id), sum(d.id), sum(e.id)
from   table_10          a
       join table_100    b on (a.id = b.fkcol)
       join table_1000   c on (b.id = c.fkcol)
       join table_10000  d on (c.id = d.fkcol)
       join table_100000 e on (d.id = e.fkcol);

@@sta
