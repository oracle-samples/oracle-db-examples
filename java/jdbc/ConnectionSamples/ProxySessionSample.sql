Rem ProxySessionSample.sql
Rem
Rem Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      ProxySessionSample.sql - Complimentory SQL file for ProxySessionSample.java
Rem
Rem    DESCRIPTION
Rem      The sample shows connecting to the Oracle Database using Proxy authentication
Rem      or N-tier authentication.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    nbsundar    04/10/15 - Created
Rem

Rem This sample requires connecting as a system user that has the ability to
Rem create user and grant necessary privileges
connect system/manager

Rem Clean up before creating necesary schema
drop role select_role;
drop role insert_role;
drop role delete_role;

drop user jeff cascade;
drop user smith cascade;
drop user proxy  cascade;

Rem Create new database users "jeff", "smith" and "proxy" 
create user proxy identified by proxy;
create user jeff identified by jeffpasswd;
create user smith identified by smithpasswd;

Rem Grant necessary privileges to DB users "proxy", "jeff" and "smith" 
grant create session, connect, resource, unlimited tablespace to proxy;
grant create session, connect, resource, unlimited tablespace to jeff;
grant create session, connect, resource, unlimited tablespace to smith;

Rem Create roles and grant necessary roles to users "jeff" and "smith"
create role select_role;
create role insert_role;
create role delete_role;

Rem Connect as a proxy user 
connect proxy/proxy

Rem Create the table which will be shared with the users "jeff" and "smith"
create table proxy_account (purchase number);
insert into proxy_account values(11);
insert into proxy_account values(13);

Rem Grant the required privileges
grant select on proxy_account to select_role;
grant insert on proxy_account to insert_role;
grant delete on proxy_account to delete_role;

Rem Connect as system user to grant necessary roles to the DB users "jeff" and "smith"
connect system/manager
grant select_role, insert_role, delete_role to jeff;
grant select_role, insert_role, delete_role to smith;

Rem grant the users "jeff" and "smith" to connect through proxy with specified roles
alter user jeff grant connect through proxy with role select_role, insert_role;
alter user smith grant connect through proxy with role select_role, insert_role;

commit;
exit

