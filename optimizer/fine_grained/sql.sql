column  EXACT_MATCHING_SIGNATURE format 99999999999999999999999999999999999
set linesize 300
set tab off
column sql_text format a85
column is_shareable format a20
column IS_ROLLING_INVALID format a20
column IS_ROLLING_REFRESH_INVALID format a20
column DDL_NO_INVALIDATE format a20

select sql_id,sql_text,child_number
, is_shareable, OBJECT_STATUS, INVALIDATIONS,IS_ROLLING_INVALID,IS_ROLLING_REFRESH_INVALID  ,DDL_NO_INVALIDATE           
from v$sql
where sql_text like '%TESTFG%' and sql_text not like '%v$sql%'
order by 2;

select sql_id,is_shareable, IS_ROLLING_INVALID,IS_ROLLING_REFRESH_INVALID
from v$sql
where sql_text like '%TESTVG%' and sql_text not like '%v$sql%'
order by 2;
