connect system/telstar

set echo on

drop user epiqtest cascade;

create user epiqtest identified by epiqtest default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,ctxapp to epiqtest;

connect epiqtest/epiqtest

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

create index bike_items_idx on bike_items (descrip)
indextype is ctxsys.context
parameters ('nopopulate sync(manual)')
local;


update bike_items set descrip = 'foo bar' where id = 7;

commit;

-- no sync

exec ctx_ddl.create_shadow_index('bike_items_idx')

--update bike_items set descrip = 'foo bar' where id = 7;
delete from bike_items where id = 7;

commit;

exec ctx_ddl.recreate_index_online('bike_items_idx', 'replace NOSWAP', 1, 'P1')

exec ctx_ddl.recreate_index_online('bike_items_idx', 'replace NOSWAP', 1, 'P2')

exec ctx_ddl.recreate_index_online('bike_items_idx', 'replace NOSWAP', 1, 'P3')

exec ctx_ddl.exchange_shadow_index('bike_items_idx', 'P1')
exec ctx_ddl.exchange_shadow_index('bike_items_idx', 'P2')
exec ctx_ddl.exchange_shadow_index('bike_items_idx', 'P3')
exec ctx_ddl.exchange_shadow_index('bike_items_idx')
