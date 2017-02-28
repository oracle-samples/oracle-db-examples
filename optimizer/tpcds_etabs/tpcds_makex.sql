set serveroutput on
set feedback off
set echo off
set termout off

spool tpcds_etabs.sql

declare
  sep char(1);
  datat user_tab_columns.data_type%type;
begin
  dbms_output.put_line('create or replace directory tpcsd_load_dir as ''/tmp/tpcdsload'';');
  for tabl in (select table_name from user_tables where table_name not in (select table_name from user_external_tables) and substr(table_name,1,2) <> 'S_' order by 1)
  loop
     dbms_output.put_line('-------------------------------------------------------------------------------');
     dbms_output.put_line('drop table X_'||tabl.table_name||';');
     dbms_output.put_line('create table X_'||tabl.table_name||' (');
     sep := ' ';
     for tabc in (select * from user_tab_columns where table_name = tabl.table_name order by column_id)
     loop
        datat := tabc.data_type;
        if (datat = 'CHAR' or datat = 'VARCHAR2') 
        then
           datat := datat||'('||tabc.data_length||')';
        end if;
        if (datat = 'NUMBER')
        then
           if (tabc.data_precision is null) 
           then
              datat := datat||'(38)';
           else
              datat := datat||'('||tabc.data_precision||','||tabc.data_scale||')';
           end if;
        end if;
        dbms_output.put_line(sep||tabc.column_name||' '||datat);        
        sep := ',';
     end loop;
     sep := ' ';
     dbms_output.put_line(')'); 
     dbms_output.put_line('organization external (type oracle_loader default directory tpcsd_load_dir access parameters ('); 
     dbms_output.put_line('RECORDS DELIMITED BY NEWLINE'); 
     dbms_output.put_line('FIELDS TERMINATED BY ''|'''); 
     dbms_output.put_line('('); 
     for tabc in (select * from user_tab_columns where table_name = tabl.table_name order by column_id)
     loop
        if (tabc.data_type = 'DATE')
        then
          dbms_output.put_line(sep||tabc.column_name||' date "YYYY-MM-DD"'); 
        else
          dbms_output.put_line(sep||tabc.column_name); 
        end if;
        sep := ',';
     end loop;
     dbms_output.put_line(')) location (''' || lower(tabl.table_name) ||'.dat'')'); 
     dbms_output.put_line(');'); 
  end loop;
end;
/

spool off
