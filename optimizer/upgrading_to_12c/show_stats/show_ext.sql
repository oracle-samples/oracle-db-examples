PROMPT ======================================================================================
PROMPT Show system-created and user-created extended statistics for a schema
PROMPT ======================================================================================
set trims on
set feedback off
set linesize 200
set pagesize 1000
set long 10000
set verify off
column table_name format a40
column extension format a70
column extension_name format a50
set serveroutput on

accept schema prompt 'Enter the name of the schema to check: '

PROMPT
PROMPT System-created extensions...
PROMPT
select table_name,extension,extension_name 
from dba_stat_extensions
where owner = upper('&schema')
and creator = 'SYSTEM'
order by table_name,extension_name;

PROMPT
PROMPT User-created extensions...
PROMPT
select table_name,extension,extension_name 
from dba_stat_extensions
where owner = upper('&schema')
and creator = 'USER'
order by table_name,extension_name;
