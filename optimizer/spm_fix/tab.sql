set echo on
spool tab
--
-- Create two tables with a skewed dataset
--
drop table t1 purge;
drop table t2 purge;

create table t1 (a number(10), b varchar2(1000), c number(10), d number(10));


var str VARCHAR2(10)
exec :str := dbms_random.string('u',10);
insert /*+ APPEND */ into t1
select DECODE(parity, 0,rn, 1,rn+1000000), :str, 1, DECODE(parity, 0,rn, 1,10)
from (
    select trunc((rownum+1)/2) as rn, mod(rownum+1,2) as parity
    from (select null from dual connect by level <= 1000)
       , (select null from dual connect by level <= 500)
     );

commit;

create table t2 as select * from t1;

create index t1i on t1 (a);
create index t2i on t2 (a);

--
-- Gather with histograms
--
@@gatherh
spool off
