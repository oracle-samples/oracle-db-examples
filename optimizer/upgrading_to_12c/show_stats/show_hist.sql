PROMPT ======================================================================================
PROMPT Show histograms and the METHOD_OPT used to create them
PROMPT This script works on Oracle Database 12c only.
PROMPT If the METHOD_OPT shown for a histogram is "FOR ALL COLUMNS SIZE AUTO"
PROMPT then this implies that the histogram was created automatically
PROMPT based on column usage.
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
PROMPT Histograms and METHOD_OPT parameter...
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
  cursor operation is
    select to_char(end_time,'yyyy-mm-dd hh24:mi') as end_time
          ,doot.target
          ,extract(xmltype(notes),'//param[@name="method_opt"]/@val').getStringVal()  as operation
    from  dba_optstat_operations,
    (  select opid,
              target
       from   dba_optstat_operation_tasks
       where  target = ptarget 
       and    status = 'COMPLETED' 
       and    end_time is not null
       order by end_time desc fetch first row only) doot
    where  id = doot.opid
    and    status = 'COMPLETED' 
    and    end_time is not null;

begin
    for h in histograms
    loop
       n:=n+1;
       if (n=1)
       then
          dbms_output.put_line(rpad('Table',40)||' '||rpad('Column',40)||' '||rpad('Histogram',15)||' '||rpad('Time',19)||rpad('METHOD_OPT',30));
          dbms_output.put_line(rpad('-',150,'-'));
       end if;
       ptarget := h.owner || '.' || h.table_name;
       dbms_output.put(rpad(ptarget,40)||' '||rpad(h.column_name,40)||' '||rpad(h.histogram,15)||' ');
       for o in operation
       loop
          dbms_output.put(o.end_time||'   '||'('||o.operation||')');
          dbms_output.put_line('');
       end loop;
    end loop;
    if (n=0)
    then
       dbms_output.put_line('None found');
    end if;
end;
/
