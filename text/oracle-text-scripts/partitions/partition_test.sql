set echo on
set linesize 132

connect / as sysdba

drop user fred cascade;

grant connect,resource,ctxapp,unlimited tablespace to fred identified by fred;

connect fred/fred

-- create a partitioned base table

drop table bike_items;

create table bike_items (id number primary key,
  price number,
  descrip varchar2(40)
)
partition by range (price)
( partition p1 values less than  (  10 ),
  partition p2 values less than  ( 100 ),
  partition p3 values less than ( maxvalue ) 
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

create index bike_items_idx on bike_items (descrip)
indextype is ctxsys.context
parameters ('memory 20M')
local  /* LOCAL keyword means one index per partition */
;

-- log on as SYS and check the options for the index and partitions:

connect / as sysdba

-- index

select idx_option from ctxsys.dr$index where idx_id = (
  select idx_id
     from ctxsys.dr$index, all_users
   where idx_owner# = user_id
   and idx_name = 'BIKE_ITEMS_IDX'
   and username = 'ROGER'
)
/

-- partitions

select ixp_option from ctxsys.dr$index_partition where ixp_idx_id = (
  select idx_id
     from ctxsys.dr$index, all_users
   where idx_owner# = user_id
   and idx_name = 'BIKE_ITEMS_IDX'
   and username = 'FRED'
)
/
