-- JDBC connection string looks like:
-- jdbc:oracle:thin:@localhost:1521:ses


alter user scott account unlock;
grant connect,resource to scott identified by tiger;
connect scott/tiger

drop table my_table;

create table my_table (
  key                varchar2(2000) primary key,
  url                varchar2(2000),
  content            varchar2(4000),
  lastmodifieddate   date,
  lang               varchar2(2000),
  title              varchar2(2000),
  auth_list          varchar2(2000)
);

-- remember, auth_list is our "Security Attributes" column

-- the first document is visible only to the user sesuser1nt

insert into my_table values ('doc1', 'doc1', 'the quick brown fox jumps over the lazy dog', sysdate, 'EN', 'Database Document One', 'sesuser1');

-- the second document is visible to anyone who has the "managers" role

insert into my_table values ('doc2', 'doc2', 'le renard brun rapide saute par-dessus le chien paresseux', sysdate, 'FR', 'Database Document Two', 'manager');

drop table my_table2;

create table my_table2 (
  key                varchar2(2000) primary key,
  url                varchar2(2000),
  content            varchar2(4000),
  lastmodifieddate   date,
  lang               varchar2(2000),
  title              varchar2(2000),
  auth_list          varchar2(2000)
);

-- remember, auth_list is our "Security Attributes" column

-- the first document is visible only to the user sesuser1nt

insert into my_table values ('doc1_2', 'doc1_2', 'the quick brown fox jumps over the lazy dog', sysdate, 'EN', 'Database Document One', 'sesuser1 sesuser3');

-- the second document is visible to anyone who has the "managers" role

insert into my_table values ('doc2_2', 'doc2_2', 'le renard brun rapide saute par-dessus le chien paresseux', sysdate, 'FR', 'Database Document Two', 'manager foo');


-- The following table represents the security informat
-- Each user can have a set of roles, plus his own username

drop table user_role_map;

create table user_role_map (
  username          varchar2(2000),
  rolelist           varchar2(2000)
);

insert into user_role_map values (
  'sesuser1', 'sesuser1 superuser manager employee');
insert into user_role_map values (
  'sesuser2', 'sesuser2 manager employee'
);

commit;
