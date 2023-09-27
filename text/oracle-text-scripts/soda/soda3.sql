create or replace procedure hwf_proc_json_oracle
   IS
      c soda_collection_t;
      s number;
BEGIN
  c := dbms_soda.create_collection('DOCUMENTCOLLECTION');
  c := DBMS_SODA.open_collection('DOCUMENTCOLLECTION');
  s := c.create_index('{"name"   : "DCTASKID_I", "fields" : [{"path"     : "taskId"}]}');
  execute immediate 'create search index "DCJSON_I" on DOCUMENTCOLLECTION ("JSON_DOCUMENT") for json parameters(''sync( every "freq=secondly;interval=5") search_on text_value dataguide off'')';
END hwf_proc_json_oracle;
/

list
show errors

begin
   hwf_proc_json_oracle;
end;
/


