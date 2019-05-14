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
  for tabl in (select table_name,lower(table_name) ltnam from user_tables where table_name not in (select table_name from user_external_tables) and substr(table_name,1,2) <> 'S_' order by 1)
  loop
     dbms_output.put_line('-------------------------------------------------------------------------------');
     dbms_output.put_line('drop table X_'||tabl.table_name||';');
     dbms_output.put_line('begin');
     dbms_output.put_line('dbms_cloud.create_external_table(''X_'||tabl.table_name||''', credential_name=>''DEF_CRED_NAME'',');
     dbms_output.put_line('file_uri_list =>''https://objectstorage.YOUR_REGION.oraclecloud.com/n/CONTAINER/b/BUCKET/o/'||tabl.ltnam||'.dat'',');
     dbms_output.put_line('format => json_object(''delimiter'' value ''|''),');
     dbms_output.put_line('column_list => ''');
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
     dbms_output.put_line(''',');
     sep := ' ';
     dbms_output.put_line('field_list => ''');
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
     dbms_output.put_line('''');
     dbms_output.put_line(');');
     dbms_output.put_line('end;');
     dbms_output.put_line('/');
  end loop;
end;
/

spool off
