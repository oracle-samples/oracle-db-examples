drop table mymaster1;
drop table mydetail1;
drop table mymaster2;
drop table mydetail2;

create table mymaster1 (id number primary key, text varchar2(1))
partition by range (id) 
( partition p1 values less than ( 2 ),
  partition p2 values less than ( 4 ),
  partition p3 values less than ( maxvalue ) 
)
/

create table mydetail1(id number, text varchar2(256), lineno number);

insert into mymaster1 values (1,'x');

insert into mydetail1 values (1, 'the quick brown fox', 1);
insert into mydetail1 values (1, 'jumps over the lazy dog', 2);

insert into mymaster1 values (2,'x');

insert into mydetail1 values (2, 'now is the time for all good men', 1);
insert into mydetail1 values (2, 'to come to the aid of the party', 2);

exec ctx_ddl.drop_preference  ('mymds')
exec ctx_ddl.create_preference('mymds', 'DETAIL_DATASTORE')
exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_TABLE',  'mydetail1')
exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_KEY',    'id')
exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_LINENO', 'lineno')
exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_TEXT',   'text')

create index myindex1 on mymaster1(text)
indextype is ctxsys.context
local
parameters ('datastore mymds')
/

select * from mymaster1 where contains (text, 'dog') > 0;
select * from mymaster1 where contains (text, 'good men AND party') > 0;

----------------------------------------------------

create table mymaster2 (id number primary key, text varchar2(1));

create table mydetail2(id number, text varchar2(256), lineno number);

insert into mymaster2 values (3,'x');

insert into mydetail2 values (3, 'england expects that every', 1);
insert into mydetail2 values (3, 'man will do his duty', 2);

insert into mymaster2 values (4,'x');

insert into mydetail2 values (4, 'the only thing we have to fear', 1);
insert into mydetail2 values (4, 'is fear itself', 2);

--exec ctx_ddl.drop_preference  ('mymds')
--exec ctx_ddl.create_preference('mymds', 'DETAIL_DATASTORE')
--exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_TABLE',  'mydetail1')
--exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_KEY',    'id')
--exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_LINENO', 'lineno')
--exec ctx_ddl.set_attribute    ('mymds', 'DETAIL_TEXT',   'text')

create index myindex2 on mymaster2(text)
indextype is ctxsys.context
parameters ('datastore mymds')
/

-- drop primary key constraints on both tables
-- must do this using dynamic SQL as we don't know constraint name

set serverout on

declare
  cname varchar2(30);
  dsql  varchar2(256);
begin

  select constraint_name into cname from user_constraints
  where table_name = 'MYMASTER1' and constraint_type = 'P';
  dsql := 'alter table mymaster1 drop constraint '||cname;
  dbms_output.put_line(dsql);
  execute immediate (dsql);

  select constraint_name into cname from user_constraints
  where table_name = 'MYMASTER2' and constraint_type = 'P';
  dsql := 'alter table mymaster2 drop constraint '||cname;
  dbms_output.put_line(dsql);
  execute immediate (dsql);

end;
/

alter table mymaster1
  exchange partition p2 with table mymaster2
  including indexes 
  without validation
/

-- drop the temporary table

drop table mymaster2;

-- reinstate primary key constraint on main table

alter table mymaster1 add primary key (id);
