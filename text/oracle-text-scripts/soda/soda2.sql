create or replace procedure hwf_proc_json_oracle
   IS
      v_banner varchar2(100);
      plsql_block varchar2(2000);
      metadata varchar2(1000);
      i integer;
      indx_1 varchar2(1000);
BEGIN
      plsql_block := 'declare c soda_collection_t; m varchar2(1000);' ||
                     'begin ' ||
                        'm := ' || metadata || ';' ||
                        'c:= dbms_soda.create_collection(''DOCUMENTCOLLECTION'');' ||
                     'end;';
                     indx_1 := 'declare c soda_collection_t; s NUMBER;' ||
                        'begin '||
                           'c := DBMS_SODA.open_collection(''DOCUMENTCOLLECTION'');' ||
                           's := c.create_index(''{"name"   : "DCTASKID_I", "fields" : [{"path"     : "taskId"}]}'');' ||
                        'end;';
                         execute immediate 'create search index "DCJSON_I" on DOCUMENTCOLLECTION ("JSON_DOCUMENT") for json parameters(''sync( every "freq=secondly;interval=5") search_on text_value dataguide off'')';
     execute immediate  indx_1;
END hwf_proc_json_oracle;
/

list
show errors

begin
   hwf_proc_json_oracle;
end;
/

