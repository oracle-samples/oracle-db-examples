set define off

drop table t;

create table t (text varchar2(2000));

insert into t values ('this text contains the word bold, but does not have any bold text in it<p></p>');
insert into t values ('this text contains text that is <span style="font-weight: bold;">emphasised</span>&nbsp;but does not contain the word itself<p></p>');

exec ctx_ddl.drop_datastore('my_mcds')
exec ctx_ddl.create_preference('my_mcds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute('my_mcds', 'COLUMNS', '''<x>''||text')

exec ctx_ddl.drop_section_group('my_xmlsg')
exec ctx_ddl.create_section_group('my_xmlsg', 'xml_section_group')

begin
  ctx_ddl.drop_preference('RDF_VALUE_STORAGE');
end;
/
begin
  ctx_ddl.create_preference('RDF_VALUE_STORAGE', 'BASIC_STORAGE');
  ctx_ddl.set_attribute('RDF_VALUE_STORAGE', 'I_TABLE_CLAUSE',' TABLESPACE USERS ');
  ctx_ddl.set_attribute('RDF_VALUE_STORAGE', 'K_TABLE_CLAUSE',' TABLESPACE USERS ');
  ctx_ddl.set_attribute('RDF_VALUE_STORAGE', 'R_TABLE_CLAUSE',' TABLESPACE USERS LOB(DATA) STORE AS (CACHE)');
  ctx_ddl.set_attribute('RDF_VALUE_STORAGE', 'N_TABLE_CLAUSE',' TABLESPACE USERS ');
  ctx_ddl.set_attribute('RDF_VALUE_STORAGE', 'I_INDEX_CLAUSE',' TABLESPACE USERS COMPRESS 2');
  ctx_ddl.set_attribute('RDF_VALUE_STORAGE', 'P_TABLE_CLAUSE',' TABLESPACE USERS ');
  ctx_ddl.set_attribute('RDF_VALUE_STORAGE', 'S_TABLE_CLAUSE',' TABLESPACE USERS NOCOMPRESS');
end;
/

create index ti on t (text) indextype is ctxsys.context
parameters ('datastore my_mcds section group my_xmlsg storage rdf_value_storage');

select * from t where contains (text, 'bold')>0;

