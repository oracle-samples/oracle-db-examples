select /* PATCHTEST*/ /*+ FULL(tab1) */ num
from   tab1
where  id = 10;

@plan
