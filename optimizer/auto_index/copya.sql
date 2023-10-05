--
-- This script lists auto indexes from DBA_IND_COLUMNS
-- and creates DDL for a non-auto-index copy
--
-- You can use it to copy automatic indexes from a clone
-- database to create non-auto copies on the source 
--
-- Spool the output from this script (on the clone) and execute the output DDL commands on the source
--
--
set serveroutput on
set feedback off

declare
   cursor c1 is
     select index_owner,index_name,table_owner,table_name,column_name
     from   dba_ind_columns
     where  (index_owner,index_name) in (select owner,index_name from dba_indexes 
                                         where auto = 'YES' and visibility = 'VISIBLE')
     order by index_owner,index_name,column_position;
   po varchar2(100) := 'X';
   pn varchar2(100) := 'X';
   iname varchar2(100);
   sep varchar2(1)  := '';
begin
   for c in c1
   loop
      --dbms_output.put_line(c.index_name);
      if (po != c.index_owner or pn != c.index_name)
      then
         if (po != 'X')
         then
            dbms_output.put_line(');');
         end if;
         sep := '';
         iname := upper(substr(c.index_name,8));
         dbms_output.put('create index "'||c.index_owner||'".AUTO_COPY_'||iname|| ' on "'||c.table_owner||'"."'||c.table_name||'" (');
         dbms_output.put(sep||'"'||c.column_name||'"');
         sep := ',';
      else
         dbms_output.put(sep||c.column_name);
      end if;
      po := c.index_owner;
      pn := c.index_name;
   end loop;
end;
/
