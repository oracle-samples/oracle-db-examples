set linesize 1000
set trims on 
set pagesize 1000
column table_name format a30
column column_name format a30
column hostogram format a30

select column_name,histogram from user_tab_col_statistics
where table_name = 'SALES'
order by 1
/
