connect system/welcome1

create user testuser identified by testuser;
grant connect,resource to testuser;

connect testuser/testuser

drop table testtable;

create table testtable (
  url              varchar2(2000),
  content          clob,
  lastmodifieddate date,
  key              varchar2(80),
  lang             varchar2(2)
);

insert into testtable values (
  'foo',
  '<atr1>foo<attr1> <attr2 "foobar=flibble">foo2</attr2> the contents of the document',
  sysdate,
  'foo',
  'EN'
);
commit
;
