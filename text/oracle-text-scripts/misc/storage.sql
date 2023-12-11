drop table t;

create table t(c varchar2(200));

exec ctx_ddl.drop_preference('mystor')
exec ctx_ddl.create_preference('mystor','BASIC_STORAGE')

begin
-- ctx_ddl.set_attribute('mystor', 'I_TABLE_CLAUSE', 'tablespace USERS');
-- ctx_ddl.set_attribute('mystor', 'K_TABLE_CLAUSE', 'tablespace USERS');
 ctx_ddl.set_attribute('mystor', 'R_TABLE_CLAUSE', 'tablespace USERS lob (data) store as (cache)');
-- ctx_ddl.set_attribute('mystor', 'N_TABLE_CLAUSE', 'tablespace USERS');
-- ctx_ddl.set_attribute('mystor', 'I_INDEX_CLAUSE', 'tablespace USERS compress 2');
--   ctx_ddl.set_attribute('mystor', 'P_TABLE_CLAUSE', 'tablespace USERS');
  null;
end;
/


create index i on t(c) indextype is ctxsys.context parameters ('storage mystor');
