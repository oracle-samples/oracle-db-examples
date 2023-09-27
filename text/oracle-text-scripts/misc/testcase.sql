-- connect system/yourpassword

drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp;
grant connect,resource,ctxapp to testuser;

-- use one of these depending on whether you're on windows or linux

$ imp testuser/testuser file=testuser2.dmp full=y

-- !imp testuser/testuser file=testuser2.dmp full=y

connect testuser/testuser

create index CONTACT_INDEX
  on EXT_CONTACTS
      (CONT_FNAME)
  indextype is ctxsys.context
  filter by
    APPLICATION_CODE,
    CONT_ACTIVE_FLG
/

select cont_FName
from ext_contacts c, parties_relations r
where 
    r.party_id_from = '50008'
    and contains(cont_FName, 'john and alan and crm')>0
/


