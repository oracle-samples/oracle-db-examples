-- Execute this script on PCATALOG PDB database as SYSDBA user

set echo on

alter session enable shard ddl;

-- DROP TABLESPACE products;
-- DROP TABLESPACE emea;
-- DROP TABLESPACE apac;

CREATE TABLESPACE products;
CREATE TABLESPACE emea IN SHARDSPACE s_emea;
CREATE TABLESPACE apac IN SHARDSPACE s_apac;

-- drop user app_schema cascade;
create user app_schema identified by "CHANGE_ME";
grant all privileges to app_schema;
grant gsmadmin_role to app_schema;
grant select_catalog_role to app_schema;
grant connect, resource to app_schema;
grant dba to app_schema;
grant execute on dbms_crypto to app_schema;

alter user app_schema quota unlimited on products;
alter user app_schema quota unlimited on emea;
alter user app_schema quota unlimited on apac;
