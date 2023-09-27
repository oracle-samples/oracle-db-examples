set timing on

create table mytable (id number, 
   title varchar2(4000), 
   create_date1 date,
   create_date2 date, 
   num_code1 number,
   num_code2 number);

insert into mytable values (1, 'the quick brown fox jumps over the lazy dog', sysdate, sysdate, 1, 1);

insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;
insert into mytable select * from mytable;

update mytable set id=rownum;

create index mytable_id on mytable(id);

update mytable set num_code1=trunc(dbms_random.value(0,100000))+1, create_date1=sysdate-(trunc(dbms_random.value(0,10000)));

commit;

update mytable set num_code2=num_code1, create_date2=create_date1;

create index mytable_num_code1 on mytable (num_code1);

create index mytable_num_code2 on mytable (num_code2);

create table small_table (text varchar2(2000));

insert into small_table values ('hello world');

create index small_table_index (text) indextype is ctxsys.context;

insert into small_table values ('hello again');

create index mytable_title_index on mytable (title) indextype is ctxsys.context
filter by num_code2
order by create_date2;

-- create table mytable2 as select * from mytable unrecoverable;

--select count(*) from mytable where contains (title, 'fox') > 0
--and num_code=12345;

--create index title_index2 on mytable2 (title) indextype is ctxsys.context
--filter by num_code
--order by num_code;

--select count(*) from mytable where contains (title, 'fox') > 0
--and num_code=9991;

--select count(*) from mytable2 where contains (title, 'fox') > 0
--and num_code=9991;
