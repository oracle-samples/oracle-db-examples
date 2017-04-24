select /* PATCHTEST*/
sum(num)
from   tab1
where  id in (select /*+ FULL(tab2) */ id
              from   tab2
              where  ty = 'T10');

@plan
