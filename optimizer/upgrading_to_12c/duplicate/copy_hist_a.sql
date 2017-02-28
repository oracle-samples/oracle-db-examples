PROMPT =======================================================================================
PROMPT Generate a script to create table histogram preferences based on example schema.
PROMPT AUTO histogram creation is enabled for columns that don't already have a histogram.
PROMPT This enables new histograms to be created if skews are found.
PROMPT =======================================================================================
whenever sqlerror exit

set serveroutput on
set verify off
set feedback off
set linesize 1000
set trims on

accept schema prompt 'Enter the name of the schema to copy: '

PROMPT Table histogram script...

spool gen_copy_hist_a.sql
declare
  n number(10) := 0;
  tname varchar2(100);
  cursor tlist is
    select distinct cs.owner,cs.table_name
    from  dba_tab_col_statistics cs,
          dba_tables t
    where cs.histogram is not null
    and   cs.histogram != 'NONE'
    and   cs.owner = upper('&schema')
    and   t.owner = upper('&schema')
    and   t.table_name = cs.table_name
    order by cs.owner,cs.table_name;
  cursor collist is
    select column_name
    from  dba_tab_col_statistics
    where histogram is not null
    and   histogram != 'NONE'
    and   owner = upper('&schema')
    and   table_name = tname
    order by owner,table_name,column_name;
begin
  dbms_output.put_line('PROMPT NOTE! It is assumed that global or schema METHOD_OPT is its default value.');
  dbms_output.put_line('PROMPT For example:');
  dbms_output.put_line('PROMPT    EXEC DBMS_STATS.SET_GLOBAL_PREFS(''METHOD_OPT'',''FOR ALL COLUMNS SIZE AUTO'')');
  dbms_output.put_line('PROMPT Alternatively:');
  dbms_output.put_line('PROMPT    EXEC DBMS_STATS.SET_SCHEMA_PREFS(''&schema'',''METHOD_OPT'',''FOR ALL COLUMNS SIZE AUTO'')');
  for t in tlist
  loop
     dbms_output.put('exec dbms_stats.set_table_prefs('''||t.owner||''','''||t.table_name||''',''METHOD_OPT'',');
     dbms_output.put('''FOR ALL COLUMNS SIZE AUTO, FOR COLUMNS ');
     tname := t.table_name;
     for c in collist
     loop
        dbms_output.put(c.column_name||' ');
     end loop;
     dbms_output.put('SIZE 254'')');
     dbms_output.put_line('');
  end loop;
end;
/
spool off
