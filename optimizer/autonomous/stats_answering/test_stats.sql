set echo on
set timing on
set linesize 250
set trims on
column MAX(TXT1) format a30
column MIN(TXT1) format a30
column MAX(TXT2) format a30
column MIN(TXT2) format a30

alter session set statistics_level = 'ALL';

--
-- The following queries use stats answering
--
select max(num0),min(num1) from fact1;
@plan
pause p...

select max(num0),min(num1),min(txt1),max(txt1),count(*) from fact1;
@plan
pause p...

select max(txt1),min(txt1),count(txt1) from fact1;
@plan
pause p...

--
-- Selecting SYSDATE first because SQLCL executes
-- a query to retrieve NLS information and we are not
-- interested in seeing that query plan.
--
select sysdate from dual;
select max(dt1) from fact1;
@plan
pause p...

select approx_count_distinct(num1) from fact1;
@plan
pause p...

--
-- The transformation can be used in more complex queries
--
select * from dim1 where dnum = (select max(num1) from fact1);
@plan
pause p...

--
-- The following queries do not use stats query answering.
-- 

--
-- Operating on the aggregate column
--
select max(num1)+1 from fact1 where num1 > 0;
@plan
pause p...

--
-- WHERE clause
--
select max(num1) from fact1 where num1 > 0;
@plan
pause p...

--
-- TXT2 column is VARCHAR2(100) - too wide
--
select min(txt2), max(txt2) from fact1;
@plan
pause p...

--
-- Not a supported aggregate
--
select sum(num1) from fact1;
@plan
pause p...

--
-- Incidentally, the result cache helps us 
-- out instead. If the query is executed a 
-- second time, we can get the result from cache.
--
select sum(num1) from fact1;
@plan
pause p...

--
-- Not a simple column aggregate
--
select max(num1+10) from fact1;
@plan
pause p...

--
-- Let's get a baseline elapsed time for this query
--
select /* RUN1 */ max(num0),min(num0),min(num1),max(num1) from fact1;
-- Note the short elapsed time because we are using stats
pause p...

--
-- DML prevents us from using stats to answer our query
-- so we'll insert a row and re-try the "RUN1" query again.
-- I'm using a different comment (RUN2) to change the query text so we
-- get a new query in the cursor cache. It's the same query though
-- of course.
--
insert into fact1 values (1,1,'XXX1','XXX1',sysdate);
commit;
select /* RUN2 */ max(num0),min(num0),min(num1),max(num1) from fact1;
-- The DML has prevented us from using stats and this is
-- reflected in the longer elapsed time.
pause p...

select /* RUN3 */ max(num0),min(num0),min(num1),max(num1) from fact1;
@plan
-- The plan reflects that stats query answering is POSSIBLE. 
-- In this case it could not be used because of the DML and this 
-- is reflected in the longer elapsed time (than the
-- RUN1 example above). 
pause p...

--
-- Get stats back up to date
--
exec dbms_stats.gather_table_stats(user,'FACT1');
