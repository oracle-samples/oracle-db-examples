set echo on

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

exec ctx_ddl.drop_stoplist  ('stop1')
exec ctx_ddl.create_stoplist('stop1', 'basic_stoplist')
exec ctx_ddl.add_stopword   ('stop1', 'wheel')
exec ctx_ddl.add_stopword   ('stop1', 'rear')

create index bike_items_idx on bike_items (descrip)
indextype is ctxsys.context
parameters ('stoplist stop1 memory 20M')
local  /* LOCAL keyword means one index per partition */
;

alter session set events = '30579 trace name context forever, level 2';

exec ctx_ddl.alter_index('bike_items_idx', 'add stopword front')

select token_text from dr#bike_items_idx0001$i;
select token_text from dr#bike_items_idx0002$i;
select token_text from dr#bike_items_idx0003$i;

select descrip from bike_items where contains( descrip, 'front' ) > 0;

