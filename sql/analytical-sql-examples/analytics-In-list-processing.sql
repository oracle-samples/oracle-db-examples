REM   Script: Analytics - In-list processing
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script uses LAG to convert string list into a set of rows.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table t purge;

create table t as select '123,456,789' acct from dual;

select distinct (instr(acct||',',',',1,level)) loc
from t
connect by level <= length(acct)- length(replace(acct,','))+1;

select substr(acct,
              nvl(lag(loc) over ( order by loc),0)+1,
              loc-nvl(lag(loc) over ( order by loc),0)-1
             ) list_as_rows
from (
   select distinct (instr(acct||',',',',1,level)) loc
   from t
   connect by level <= length(acct)-length(replace(acct,','))+1
), t


;

