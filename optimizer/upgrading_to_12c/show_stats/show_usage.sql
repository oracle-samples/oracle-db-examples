set linesize 200
set pagesize 100
set trims on
set tab off
set verify off
column column_name format a40
column table_name format a40
accept own prompt 'Enter the name of the schema to check: '

prompt COL_USAGE$ entries for chosen schema
prompt ====================================
select  c.TABLE_NAME,
        c.COLUMN_NAME,
        u.EQUALITY_PREDS,
        u.EQUIJOIN_PREDS,
        u.NONEQUIJOIN_PREDS,
        u.RANGE_PREDS,
        u.LIKE_PREDS,
        u.NULL_PREDS,
        u.TIMESTAMP
from sys.col_usage$ u,
     dba_tab_columns c,
     dba_objects o
where obj# = o.object_id 
and   c.owner = upper('&own')
and   intcol# = column_id
and   o.owner = upper('&own')
and   o.object_name = c.table_name;
