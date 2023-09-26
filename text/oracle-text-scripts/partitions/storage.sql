set echo on

connect system/oracle
drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users quota unlimited on sysaux quota unlimited on system;
grant connect,resource,ctxapp to testuser;

connect testuser/testuser

exec ctx_ddl.drop_preference('sto1')
exec ctx_ddl.create_preference('sto1', 'basic_storage')
exec ctx_ddl.set_attribute('sto1', 'i_table_clause', 'tablespace SYSAUX')

exec ctx_ddl.create_preference('sto2', 'basic_storage')
exec ctx_ddl.set_attribute('sto2', 'i_table_clause', 'tablespace USERS')

-- create a partitioned base table

drop table bike_items;

create table bike_items (id number primary key,
  price number,
  descrip varchar2(40)
)
partition by range (price)
( partition p1 values less than  (  10 ) tablespace users,
  partition p2 values less than  ( 100 ) tablespace users,
  partition p3 values less than ( maxvalue ) tablespace users 
);

insert into bike_items values (1, 2.50,  'inner tube for MTB wheel');
insert into bike_items values (2, 29,    'wheel, front, basic');
insert into bike_items values (3, 75,    'wheel, front, top quality');
insert into bike_items values (4, 1.99,  'valve caps, set of 4');
insert into bike_items values (5, 15.99, 'seat');
insert into bike_items values (6, 130,   'hydraulic disk brake, front wheel');
insert into bike_items values (7, 25,    'v-type brake, rear wheel');
insert into bike_items values (8, 750,   'full-suspension mountain bike');
insert into bike_items values (9, 250,   'mountain bike frame');
insert into bike_items values (10, 40,   'tires - pair');
insert into bike_items values (11, 45,   'wheel, rear, basic');
insert into bike_items values (12, 89.99,'wheel, rear top quality');

commit;

-- Now drop that index and create a LOCALLY PARTIONED VERSION

drop index bike_items_idx;

create index bike_items_idx on bike_items (descrip)
indextype is ctxsys.context
parameters ('memory 20M')
local (
  partition p1 parameters('storage sto1'),
  partition p2 parameters('storage sto2'),
  partition p3
)
/

