set autotrace off

DROP TABLE my_table
/
CREATE TABLE my_table (column1  VARCHAR2(60))
/ 
INSERT ALL
 INTO my_table VALUES ('test')
 INTO my_table VALUES ('testing')
 INTO my_table VALUES ('my-test')
 INTO my_table VALUES ('owr-test')
 SELECT * FROM DUAL
/ 

insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;
insert into my_table select * from my_table;

create index column1_index on my_table(column1)
/
 
set autotrace traceonly explain

SELECT count(*)
  FROM   MY_TABLE mt
  WHERE  mt.COLUMN1 like 'test%'
/ 
