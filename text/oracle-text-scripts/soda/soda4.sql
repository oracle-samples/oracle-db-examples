DECLARE
      c soda_collection_t;
      s number;
BEGIN
  c := dbms_soda.create_collection('DOCUMENTCOLLECTION2');
  c := DBMS_SODA.open_collection('DOCUMENTCOLLECTION2');
  s := c.create_index('{"name"   : "DCTASKID_I2", "fields" : [{"path"     : "taskId"}]}');
  execute immediate 'create search index "DCJSON_I2" on DOCUMENTCOLLECTION2 ("JSON_DOCUMENT") for json parameters(''sync( every "freq=secondly;interval=5") search_on text_value dataguide off'')';
END hwf_proc_json_oracle;
/


