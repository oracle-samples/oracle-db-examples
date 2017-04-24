select /* PATCHTEST*/  /*+ USE_HASH(tab1 tab2) */
sum(num)
from   tab1
where  id in (select id
              from   tab2
              where  ty = 'T10');

@plan
