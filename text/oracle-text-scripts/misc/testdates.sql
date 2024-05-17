create user testuser identified by testuser default tablespace users temporary tablespace temp;

grant connect,resource to testuser;

connect testuser/testuser

create table target
  (url              varchar2(2000),   -- required                
   content          clob,             -- required
   lastmodifieddate date,             -- required
   key              varchar2(200),    -- required
   lang             varchar2(2),      -- required
   mytitle          varchar2(200),    -- simple attribute
   anotherdate      date,             -- date attribute
   allowedusers     varchar2(2000),   -- security attribute 1
   allowedgroups    varchar2(2000)    -- security attribute 2
  );

-- This table contains the mapping between users and groups
-- It will be used by the authorization plugin to fetch values to
-- match against the security attribute columns above

create table usergroups
  (username varchar2(30),
   grouplist varchar2(30)
  );

insert into target
  (url,
   content,
   lastmodifieddate,
   key,
   lang,
   mytitle,
   allowedusers,
   allowedgroups
 ) values (
   '?doc1',
   'the quick brown fox jumps over the lazy dog',
   sysdate,
   'doc1',
   'en',
   'The Document Title',
   sysdate,
   'sesuser1',
   'group1 group2'
  );


insert into target
  (url,
   content,
   lastmodifieddate,
   key,
   lang,
   mytitle,
   allowedusers,
   allowedgroups
  ) values (
   '?doc2',
   'the quick rabbit jumps over the lazy dog',
   sysdate,
   'doc2',
   'en',
   'Another Title',
   sysdate,
   'sesuser1',
   'group1'
  );

-- sesuser1 is in group2 only

insert into usergroups
  (username,
   grouplist
  ) values (
   'sesuser1',
   'group2');

-- sesuser2 is in groups 1 and 2

insert into usergroups
  (username,
   grouplist
  ) values (
   'sesuser2',
   'group1 group2'); 
