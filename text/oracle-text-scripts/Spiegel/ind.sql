create index bike_items_global_idx on bike_items_g (descrip)
indextype is ctxsys.context
parameters ('memory 20M')
/* no LOCAL keyword */
;

create index bike_items_local_idx on bike_items_p (descrip)
indextype is ctxsys.context
parameters ('memory 20M')
local  /* LOCAL keyword means one index per partition */
;

