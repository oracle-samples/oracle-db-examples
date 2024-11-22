connect sys/welcome1 as sysdba
drop user newtestuser cascade;
create user newtestuser identified by newtestuser default tablespace users temporary tablespace temp;
grant connect,resource,ctxapp,create job to newtestuser;

connect newtestuser/newtestuser

create table context_test(abstract clob, result_title varchar2(255));
insert into context_test values ('test', 'this is the result for test');
commit;
BEGIN
 CTX_DDL.create_preference('s_storage_pref', 'BASIC_STORAGE');
 CTX_DDL.set_attribute('s_storage_pref', 'I_TABLE_CLAUSE', 'tablespace users');
 CTX_DDL.set_attribute('s_storage_pref', 'K_TABLE_CLAUSE', 'tablespace users');
 CTX_DDL.set_attribute('s_storage_pref', 'R_TABLE_CLAUSE', 'tablespace users lob (data) store as (disable storage in row cache)');
 CTX_DDL.set_attribute('s_storage_pref', 'N_TABLE_CLAUSE', 'tablespace users');
 CTX_DDL.set_attribute('s_storage_pref', 'I_INDEX_CLAUSE', 'tablespace users compress 2');
 CTX_DDL.set_attribute('s_storage_pref', 'P_TABLE_CLAUSE', 'tablespace users');
END;
/
BEGIN
 CTX_DDL.create_preference('s_data_store','MULTI_COLUMN_DATASTORE');
 CTX_DDL.set_attribute('s_data_store','columns','abstract');
 CTX_DDL.set_attribute('s_data_store', 'FILTER','N,N,N,N,N');
END;
/

BEGIN
 CTX_DDL.create_section_group ('s_data_store_sg','BASIC_SECTION_GROUP');
 CTX_DDL.add_field_section('s_data_store_sg', 'abstract', 'abstract', TRUE);
 CTX_DDL.add_field_section('s_data_store_sg', 'result_title', 'result_title', TRUE);
END;
/

CREATE INDEX context_test_I ON context_test(ABSTRACT)
 INDEXTYPE IS CTXSYS.CONTEXT
 PARAMETERS('STORAGE s_storage_pref DATASTORE s_data_store SECTION GROUP s_data_store_sg
 SYNC (EVERY "FREQ=MINUTELY; INTERVAL=15" )');
