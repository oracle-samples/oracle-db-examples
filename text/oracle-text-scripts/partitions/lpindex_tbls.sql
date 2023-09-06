drop table bike_items;

-- We'll create two identical tables. Both are partitioned by price, but one
-- will have a "global" index, the other will have a local partition index

-- The 'global' table

drop table bike_items_g;

create table bike_items_g (id number primary key,
  price number,
  descrip varchar2(40)
)
partition by range (price)
( partition p1 values less than  (   2 ) tablespace users,
  partition p2 values less than  (   5 ) tablespace users,
  partition p3 values less than  (  10 ) tablespace users,
  partition p4 values less than  (  15 ) tablespace users,
  partition p5 values less than  (  20 ) tablespace users,
  partition p6 values less than  (  50 ) tablespace users,
  partition p7 values less than  ( 100 ) tablespace users,
  partition p8 values less than  ( 150 ) tablespace users,
  partition p9 values less than  ( 500 ) tablespace users,
  partition p10 values less than ( maxvalue ) tablespace users 
);

insert into bike_items_g values (1, 2.50,  'inner tube for MTB wheel');
insert into bike_items_g values (2, 29,    'wheel, front, basic');
insert into bike_items_g values (3, 75,    'wheel, front, top quality');
insert into bike_items_g values (4, 1.99,  'valve caps, set of 4');
insert into bike_items_g values (5, 15.99, 'seat');
insert into bike_items_g values (6, 130,   'hydraulic disk brake, front wheel');
insert into bike_items_g values (7, 25,    'v-type brake, rear wheel');
insert into bike_items_g values (8, 750,   'full-suspension mountain bike');
insert into bike_items_g values (9, 250,   'mountain bike frame');
insert into bike_items_g values (10, 40,   'tires - pair');
insert into bike_items_g values (11, 45,   'wheel, rear, basic');
insert into bike_items_g values (12, 89.99,'wheel, rear top quality');

commit;

-- The table for the local partition index

drop table bike_items_p;

create table bike_items_p (id number primary key,
  price number,
  descrip varchar2(40)
)
partition by range (price)
( partition p1 values less than  (   2 ) tablespace users,
  partition p2 values less than  (   5 ) tablespace users,
  partition p3 values less than  (  10 ) tablespace users,
  partition p4 values less than  (  15 ) tablespace users,
  partition p5 values less than  (  20 ) tablespace users,
  partition p6 values less than  (  50 ) tablespace users,
  partition p7 values less than  ( 100 ) tablespace users,
  partition p8 values less than  ( 150 ) tablespace users,
  partition p9 values less than  ( 500 ) tablespace users,
  partition p10 values less than ( maxvalue ) tablespace users 
);

insert into bike_items_p values (1, 2.50,  'inner tube for MTB wheel');
insert into bike_items_p values (2, 29,    'wheel, front, basic');
insert into bike_items_p values (3, 75,    'wheel, front, top quality');
insert into bike_items_p values (4, 1.99,  'valve caps, set of 4');
insert into bike_items_p values (5, 15.99, 'seat');
insert into bike_items_p values (6, 130,   'hydraulic disk brake, front wheel');
insert into bike_items_p values (7, 25,    'v-type brake, rear wheel');
insert into bike_items_p values (8, 750,   'full-suspension mountain bike');
insert into bike_items_p values (9, 250,   'mountain bike frame');
insert into bike_items_p values (10, 40,   'tires - pair');
insert into bike_items_p values (11, 45,   'wheel, rear, basic');
insert into bike_items_p values (12, 89.99,'wheel, rear top quality');

commit;

create index bike_items_global_idx on bike_items_g (descrip)
indextype is ctxsys.context
parameters ('memory 20M')
/* no LOCAL keyword */
;

create index bike_items_local_idx on bike_items_p (descrip)
indextype is ctxsys.context
parameters ('memory 20M')
local  /* LOCAL keyword means one index per partition */
;


