--
-- List information on tables missing stats or with stale stats
-- 
@cusr

set trims on
set tab off
column table_name format a35
column index_name format a35
set pagesize 100
set linesize 200

select table_name,stale_stats,to_char(LAST_ANALYZED,'YYYY-MM-DD HH24:MI:SS') from user_tab_statistics where table_name like 'BIGT%'
order by 1,2;

select table_name,index_name,stale_stats,to_char(LAST_ANALYZED,'YYYY-MM-DD HH24:MI:SS') from user_ind_statistics where table_name like 'BIGT%'
order by 1,2;

