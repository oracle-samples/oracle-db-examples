drop table pt2;
drop table pt1;

create table pt1 (
  id number   primary key, 
  part_key    number, 
  dummy       varchar2(1))
partition by range (part_key)
( partition p1 values less than (2),
  partition p2 values less than (maxvalue)
);

create table pt2 (
  id          number primary key, 
  part_key    number, 
  fk          number,
  line_number number, 
  text        varchar2(80),
  constraint  pt2fkc foreign key (fk) references pt1(id) )
partition by range (part_key)
( partition p1 values less than (2),
  partition p2 values less than (maxvalue)
);

insert into pt1 values (1, 1, 'x');
insert into pt1 values (2, 2, 'x');

insert into pt2 values (1, 1, 1, 1, 'the quick brown fox ');
insert into pt2 values (2, 1, 1, 2, 'jumps over the lazy dog');

insert into pt2 values (3, 2, 2, 1, 'now is the time for all good men ');
insert into pt2 values (4, 2, 2, 2, 'to come to the aid of the party');

exec ctx_ddl.drop_preference  ('mymd')
exec ctx_ddl.create_preference('mymd', 'DETAIL_DATASTORE')
exec ctx_ddl.set_attribute    ('mymd', 'DETAIL_TABLE', 'PT2')
exec ctx_ddl.set_attribute    ('mymd', 'DETAIL_KEY',   'FK')
exec ctx_ddl.set_attribute    ('mymd', 'DETAIL_TEXT',  'TEXT')
exec ctx_ddl.set_attribute    ('mymd', 'DETAIL_LINENO','LINE_NUMBER')

create index pt_index on pt1 (dummy) indextype is ctxsys.context
parameters ('datastore mymd')
local
/

