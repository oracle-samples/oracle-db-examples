PROMPT ======================================================================================
PROMPT Show SQL plan directives associated with a chosen schema
PROMPT ======================================================================================
set trims on
set feedback off
set linesize 200
set pagesize 1000
set long 10000
set verify off
column table_name format a40
column column_name format a40

accept own prompt 'Enter the name of the schema to check: '

--
-- Ensure directives are flushed
--
exec dbms_spd.flush_sql_plan_directive;

COLUMN dir_id FORMAT A20
COLUMN owner FORMAT A10
COLUMN object_name FORMAT A10
COLUMN col_name FORMAT A10

SELECT o.object_type,
       o.object_name,
       o.subobject_name col_name, 
       d.type, 
       d.state, 
       d.reason
FROM   dba_sql_plan_directives d, dba_sql_plan_dir_objects o
WHERE  d.directive_id=o.directive_id
AND    o.owner = upper('&own')
ORDER BY 1,2,3;

