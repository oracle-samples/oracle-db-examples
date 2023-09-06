connect / as sysdba

drop user ptest cascade;

drop tablespace ptest1 including contents and datafiles;
drop tablespace ptest2 including contents and datafiles;

create tablespace ptest1 datafile '/home/oracle/dbinstall/oradata/R192/ptest1.dbf' size 10m autoextend on;
create tablespace ptest2 datafile '/home/oracle/dbinstall/oradata/R192/ptest2.dbf' size 10m autoextend on;

create user ptest identified by ptest default tablespace users;

grant connect,resource,ctxapp,unlimited tablespace to ptest;

connect ptest/ptest

-- create a partitioned base table

DROP TABLE bike_items;

CREATE TABLE bike_items 
( id      NUMBER,
  price   NUMBER,
  descrip VARCHAR2(40)
)
PARTITION BY RANGE (price)
( PARTITION p1 VALUES LESS THAN  (       10 ) TABLESPACE users,
  PARTITION p2 VALUES LESS THAN  (      100 ) TABLESPACE users,
  PARTITION p3 VALUES LESS THAN  ( maxvalue ) TABLESPACE users 
);

-- add some data to that table

INSERT INTO bike_items VALUES ( 1, 2.50,  'inner tube for MTB wheel');
INSERT INTO bike_items VALUES ( 2, 29,    'wheel, front, basic');
INSERT INTO bike_items VALUES ( 3, 75,    'wheel, front, top quality');
INSERT INTO bike_items VALUES ( 4, 1.99,  'valve caps, set of 4');
INSERT INTO bike_items VALUES ( 5, 15.99, 'seat');
INSERT INTO bike_items VALUES ( 6, 130,   'hydraulic disk brake, front wheel');
INSERT INTO bike_items VALUES ( 7, 25,    'v-type brake, rear wheel');
INSERT INTO bike_items VALUES ( 8, 750,   'full-suspension mountain bike');
INSERT INTO bike_items VALUES ( 9, 250,   'mountain bike frame');
INSERT INTO bike_items VALUES (10, 40,    'tires - pair');
INSERT INTO bike_items VALUES (11, 45,    'wheel, rear, basic');
INSERT INTO bike_items VALUES (12, 89.99, 'wheel, rear top quality');


exec ctx_ddl.create_preference('part_storage'  , 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('part_storage'  , 'I_INDEX_CLAUSE', 'tablespace ptest1')

exec ctx_ddl.create_preference('index_storage' , 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('index_storage' , 'I_INDEX_CLAUSE', 'tablespace ptest2')

-- create a local partitioned index on the table

CREATE INDEX bike_items_idx ON bike_items (descrip)
INDEXTYPE IS ctxsys.context
LOCAL (
partition p1 parameters ('storage part_storage'),
partition p2 parameters ('storage part_storage'),
partition p3 parameters ('storage part_storage') )
PARAMETERS ('storage index_storage')
;

column index_name format a30
column tablespace_name format a30

select index_name, tablespace_name from user_indexes where index_name like 'DR%X';

-- now split a partition

ALTER TABLE bike_items 
  SPLIT PARTITION p2 AT ( 50 ) 
  INTO ( PARTITION p2a, PARTITION p2b );

-- rebuild index partitions
-- the first will use a specific storage clause, the second will default to the index storage

alter index bike_items_idx rebuild partition p2a parameters ('storage part_storage');
alter index bike_items_idx rebuild partition p2b;

-- sync the index

exec ctx_ddl.sync_index('bike_items_idx', '', 'p2a')
exec ctx_ddl.sync_index('bike_items_idx', '', 'p2b')

-- and try a query

select * from bike_items where contains (descrip, 'wheel') > 0;

-- check the tablespaces again
-- we should see that only one of the partitions uses the index default storage

select index_name, tablespace_name from user_indexes where index_name like 'DR%X';
