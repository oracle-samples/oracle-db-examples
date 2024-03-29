
drop index index2;

create index index2
  on table1
      (CONT_FNAME)
  indextype is ctxsys.context
  filter by
    APPLICATION_CODE,
    CONT_ACTIVE_FLG
/
