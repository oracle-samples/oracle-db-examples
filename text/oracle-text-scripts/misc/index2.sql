
drop index contact_index;

create index CONTACT_INDEX
  on EXT_CONTACTS
      (CONT_FNAME)
  indextype is ctxsys.context
  filter by
    APPLICATION_CODE,
    CONT_ACTIVE_FLG
/
