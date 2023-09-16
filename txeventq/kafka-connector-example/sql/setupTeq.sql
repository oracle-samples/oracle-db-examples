set serveroutput on

alter pluggable database all close immediate;
drop pluggable database cdb1_pdb1 including datafiles;
create pluggable database cdb1_pdb1 admin user &1 identified by &2 file_name_convert=('&3', 'pdb1');
alter pluggable database all open;
alter session set container=cdb1_pdb1;

CREATE TABLESPACE users DATAFILE 'users.dbf' SIZE 500M EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO;
ALTER USER &1
      DEFAULT TABLESPACE users;
alter user &1 quota 1G on users;

grant connect,resource to &1;
grant execute on dbms_aqadm to &1;
grant execute on dbms_aqin to &1;
grant execute on dbms_aqjms to &1;
grant execute on dbms_aq to &1;
grant select_catalog_role to &1;

