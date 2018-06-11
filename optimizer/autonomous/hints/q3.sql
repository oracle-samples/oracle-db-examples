alter session set optimizer_ignore_hints = false;

select /*+ LEADING(t1 t2) USE_NL(t2) */ 
       sum(t1.num), sum(t2.num)
from   table1 t1
join table2 t2 on (t1.id = t2.id);

@plan

alter session set optimizer_ignore_hints = true;
