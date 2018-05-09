REM
REM Demo direct path loading and stats maintenance. 
REM
set timing on
column stale format a5
column table_name format a30
column column_name format a30
column high_value format a30
column low_value format a30
column range format a10
set linesize 250
set tab off
set trims on
set echo on

spool test_load

drop table fact1 purge;
drop table fact1_source purge;

create table fact1 (num0 number(10), num1 number(10), txt1 varchar2(100));

create table fact1_source as
select * from fact1 where 1=-1;

insert /*+ APPEND */ into fact1_source
select rownum,mod(rownum,10),'XXX'||rownum
from   dual connect by rownum <= 10000;

commit;

--
-- Notice that NUM_ROWS is maintained - we have stats on initial load
--
select table_name,num_rows from user_tables where  table_name = 'FACT1_SOURCE';

pause p...

--
-- Insert more rows into FACT1
--
insert /*+ APPEND */ into fact1 select num0,1,txt1 from fact1_source;
commit;
@stat

-- Notice above that statistics are still maintained
-- even though FACT1 was not empty before
-- the INSERT. The histograms are maintained too.
pause p...

insert /*+ APPEND */ into fact1 select num0,2,txt1 from fact1_source;
commit;
@stat

-- Notice again - statistics are still maintained
-- even though FACT1 was not empty before
-- the INSERT. The histograms continue to be maintained.
pause p...

insert /*+ APPEND */ into fact1 select num0,3,txt1 from fact1_source;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,4,txt1 from fact1_source;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,5,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,6,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,7,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,8,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,9,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,10,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,11,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,12,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,13,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,14,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,15,txt1 from fact1;
commit;
@stat

insert /*+ APPEND */ into fact1 select num0,16,txt1 from fact1;
commit;
@stat
spool off
