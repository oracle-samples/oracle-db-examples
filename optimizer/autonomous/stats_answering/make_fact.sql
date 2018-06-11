REM
REM Fact table for demo statistics query answering 
REM
set timing on
set linesize 250
set tab off
set trims on
set echo on

drop table fact1 purge;
drop table fact1_source purge;

--
-- In this case we are using VARCHAR2(20)
-- We have to keep the column under 64 bytes
-- to answer aggregate queries on this column
-- using stats.
-- 
create table fact1 (num0 number(10), num1 number(10), txt1 varchar2(20), txt2 varchar2(100), dt1 date);

create table fact1_source as
select * from fact1 where 1=-1;

insert /*+ APPEND */ into fact1_source
select rownum,mod(rownum,10),'XXX'||rownum,'XXX'||rownum,sysdate-rownum
from   dual connect by rownum <= 10000;

commit;

--
-- Insert rows into FACT1
--
insert /*+ APPEND */ into fact1 select num0,0,txt1,txt2,dt1 from fact1_source;
commit;

--
-- Let's speed up row generation...
--
set autocommit on
insert /*+ APPEND */ into fact1 select num0,1,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,2,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,3,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,4,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,5,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,6,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,7,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,8,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,9,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,10,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,11,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,12,txt1,txt2,dt1 from fact1;
insert /*+ APPEND */ into fact1 select num0,13,txt1,txt2,dt1 from fact1;
set autocommit off
