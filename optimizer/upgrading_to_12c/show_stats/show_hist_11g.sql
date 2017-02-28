PROMPT ======================================================================================
PROMPT Show histograms 
PROMPT This script works on Oracle Database 11g
PROMPT ======================================================================================
set trims on
set feedback off
set linesize 200
set pagesize 1000
set long 10000
set verify off
column table_name format a40
column column_name format a40

accept schema prompt 'Enter the name of the schema to check: '

set serveroutput on

PROMPT
PROMPT Histograms...
PROMPT
declare
  n number(10) := 0;
  ptarget varchar2(1000);
  cursor histograms is
    select owner,table_name,column_id,column_name,histogram
    from   dba_tab_columns
    where  owner = upper('&schema')
    and histogram != 'NONE'
    and histogram is not null
    order by 1,2,3;
begin
   for h in histograms
   loop
      n:=n+1;
      if (n=1)
      then
         dbms_output.put_line(rpad('Table',40)||' '||rpad('Column',40)||' '||rpad('Histogram',15));
         dbms_output.put_line(rpad('-',105,'-'));
      end if;
      ptarget := h.owner || '.' || h.table_name;
      dbms_output.put(rpad(ptarget,40)||' '||rpad(h.column_name,40)||' '||rpad(h.histogram,15)||' ');
      dbms_output.put_line(' ');
   end loop;
   if (n=0)
   then
      dbms_output.put_line('None found');
   end if;
end;
/
