set serveroutput on
create user if not exists &1 identified by &2

alter pluggable database all close immediate;
drop pluggable database cdb1_pdb1 including datafiles;
drop pluggable database cdb1_pdb2 including datafiles;
drop pluggable database cdb1_pdb3 including datafiles;
drop pluggable database cdb1_pdb4 including datafiles;
create pluggable database cdb1_pdb1 &1 user &1 identified by  &2 file_name_convert=('pdb0', 'pdb1');

alter session set container=cdb1_pdb1;
alter pluggable database open;
drop tablespace users including contents and datafiles;
CREATE TABLESPACE users DATAFILE 'users3.dbf' SIZE 500M EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO;
ALTER USER &1
      DEFAULT TABLESPACE users;
alter user &1 quota 1G on users;

grant connect,resource to &1;
grant execute on dbms_aqadm to &1;
grant execute on dbms_aqin to &1;
grant execute on dbms_aqjms to &1;
grant execute on dbms_aq to &1;
grant select_catalog_role to &1;

