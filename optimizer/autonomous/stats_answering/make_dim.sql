REM
REM Small DIM table 
REM
set timing on
set linesize 250
set tab off
set trims on
set echo on

drop table dim1 purge;

create table dim1 (dnum number(10));

insert into dim1 values (13);
commit;
exec dbms_stats.gather_table_stats(user,'dim1');
