-- there is a limit of 50,000 wildcard expansions for a single term in a query 
-- (in 19c, earlier versions had lower limits)
-- unless WILDCARD_MAXTERMS is adjusted for the index
--
-- This script shows that the limit is per term, not per query as a whole
-- (if we split the term into 10 separate expansions of 6,000 each it works
-- fine) and that for a partitioned index, the limit is per partition 

set echo on

-- 1/ Unpartitioned table:

drop table x;
create table x (pk number, text varchar2(2000))
/

-- insert 60,000 rows containing word1, word2, ... word60000
declare
  counter integer := 1;
begin
  loop 
    insert into x values (counter, 'word'||to_char(counter));
    counter := counter + 1;
    exit when counter > 60000;
  end loop;
end;
/
commit;

-- create unpartitioned index
create index xi on x(text) indextype is ctxsys.context;

-- this fails

select count(*) from x where contains (text, 'word%') > 0;

-- this is the same query, but split over 10 CONTAINS
-- equivalent of running each SQE separately (?)
-- could also use UNIONs

select count(*) from x where 
   contains (text, 'word0%') >0
or contains (text, 'word1%') > 0
or contains (text, 'word2%') > 0
or contains (text, 'word3%') > 0
or contains (text, 'word4%') > 0
or contains (text, 'word5%') > 0
or contains (text, 'word6%') > 0
or contains (text, 'word7%') > 0
or contains (text, 'word8%') > 0
or contains (text, 'word9%') > 0
/

-- now we'll try a partitioned version of the table
-- just split up into 6 partitions on "pk"

drop table x;
create table x (pk number, text varchar2(2000))
partition by range (pk)
   (partition p1 values less than (10000),
    partition p2 values less than (20000),
    partition p3 values less than (30000),
    partition p4 values less than (40000),
    partition p5 values less than (50000),
    partition p6 values less than (999999))
/

-- insert 60000 rows again

declare
  counter integer := 1;
begin
  loop 
    insert into x values (counter, 'word'||to_char(counter));
    counter := counter + 1;
    exit when counter > 6000;
  end loop;
end;
/
commit;

-- create local partition index - note "local" keyword

create index xi on x(text) indextype is ctxsys.context local;

set timing on

-- this query should now work, as each partition only 
-- has 1000 expansions

select count(*) from x where contains (text, 'word%') > 0;

