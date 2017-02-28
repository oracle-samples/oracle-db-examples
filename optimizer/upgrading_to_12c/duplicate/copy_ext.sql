PROMPT ======================================================================================
PROMPT Generate script to create extended statistics based on an example schema
PROMPT ======================================================================================
set serveroutput on
set verify off
set feedback off
set linesize 1000
set trims on
set serveroutput on

accept schema prompt 'Enter the name of the schema to copy: '

spool gen_copy_ext.sql
declare
  cursor extlist is
     select table_name,extension,creator,owner 
     from dba_stat_extensions
     where owner = upper('&schema')
     order by creator,table_name,extension_name;
begin
  dbms_output.put_line('var r VARCHAR2(50)');
  for c in extlist
  loop
    dbms_output.put('exec :r := dbms_stats.create_extended_stats('''||c.owner||''','''||c.table_name||''','''||c.extension||''')');
    dbms_output.put_line(' /* '||c.creator||' */');
  end loop;
end;
/
spool off
