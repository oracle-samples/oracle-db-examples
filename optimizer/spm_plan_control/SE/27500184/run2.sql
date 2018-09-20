--
-- Run this test in SE and EE and compare hard number of hard parses
--
set linesize 280
set trims on
set pagesize 200
set tab off
set feedback off
set echo off

select a.name,b.value from v$mystat b, v$statname a where a.statistic# = b.statistic# and a.name like '%parse%hard%';
set termout off
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
set termout on
select a.name,b.value from v$mystat b, v$statname a where a.statistic# = b.statistic# and a.name like '%parse%hard%';
