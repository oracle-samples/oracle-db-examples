-- CDB1_PDB1 -> CloudBank
-- CDB1_PDB2 -> BankA
-- CDB1_PDB3 -> BankB
-- CDB1_PDB4 -> Credit Score

-- SCRIPT TO CREATE PDB'S FOR THE DEMO AND GRANT RESPECTIVE SET OF PRIVILEGES TO THE ADMIN USERS. NOTE: WE DROP PDB'S BEFORE CREATING NEW ONE'S.

set serveroutput on
alter pluggable database all close immediate INSTANCES=ALL;
drop pluggable database cdb1_pdb1 including datafiles;
create pluggable database cdb1_pdb1 admin user admin identified by test file_name_convert=('<seed_database>', 'pdb1');
drop pluggable database cdb1_pdb2 including datafiles;
create pluggable database cdb1_pdb2 admin user admin identified by test file_name_convert=('<seed_database>', 'pdb2');
drop pluggable database cdb1_pdb3 including datafiles;
create pluggable database cdb1_pdb3 admin user admin identified by test file_name_convert=('<seed_database>', 'pdb3');
drop pluggable database cdb1_pdb4 including datafiles;
create pluggable database cdb1_pdb4 admin user admin identified by test file_name_convert=('<seed_database>', 'pdb4');

ALTER PLUGGABLE DATABASE ALL OPEN;

alter system set JOB_QUEUE_PROCESSES=200;

alter session set container=cdb1_pdb1;
--drop tablespace users including contents and datafiles;
create tablespace users datafile 'users1.dbf' size 500m autoextend on MAXSIZE 5000M;
CREATE PUBLIC DATABASE LINK PDB2_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb2';
CREATE PUBLIC DATABASE LINK PDB3_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb3';
CREATE PUBLIC DATABASE LINK PDB4_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb4';
ALTER USER admin DEFAULT TABLESPACE users;

alter session set container=cdb1_pdb2;
--drop tablespace users including contents and datafiles;
create tablespace users datafile 'users2.dbf' size 500m autoextend on MAXSIZE 5000M;
CREATE PUBLIC DATABASE LINK PDB1_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb1';
CREATE PUBLIC DATABASE LINK PDB3_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb3';
CREATE PUBLIC DATABASE LINK PDB4_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb4';
ALTER USER admin DEFAULT TABLESPACE users;

alter session set container=cdb1_pdb3;
--drop tablespace users including contents and datafiles;
create tablespace users datafile 'users3.dbf' size 500m autoextend on MAXSIZE 5000M;
CREATE PUBLIC DATABASE LINK PDB1_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb1';
CREATE PUBLIC DATABASE LINK PDB2_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb2';
CREATE PUBLIC DATABASE LINK PDB4_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb4';
ALTER USER admin DEFAULT TABLESPACE users;

alter session set container=cdb1_pdb4;
--drop tablespace users including contents and datafiles;
create tablespace users datafile 'users4.dbf' size 500m autoextend on MAXSIZE 5000M;
CREATE PUBLIC DATABASE LINK PDB1_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb1';
CREATE PUBLIC DATABASE LINK PDB2_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb2';
CREATE PUBLIC DATABASE LINK PDB3_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb3';
ALTER USER admin DEFAULT TABLESPACE users;

alter session set container=cdb1_pdb1;
--grant aq_administrator_role to admin;
grant connect,resource,unlimited tablespace to admin;
--grant execute on sys.dbms_saga_adm to admin;
--grant execute on sys.dbms_saga to admin;
grant saga_adm_role to admin;
grant saga_participant_role to admin;
grant saga_connect_role to admin;
grant all on sys.saga_message_broker$ to admin;
grant all on sys.saga_participant$ to admin;
grant all on sys.saga$ to admin;
grant all on sys.saga_participant_set$ to admin;

alter session set container=cdb1_pdb2;
--grant aq_administrator_role to admin;
grant connect,resource,unlimited tablespace to admin;
--grant execute on sys.dbms_saga_adm to admin;
--grant execute on sys.dbms_saga to admin;
grant saga_adm_role to admin;
grant saga_participant_role to admin;
grant saga_connect_role to admin;
grant all on sys.saga_message_broker$ to admin;
grant all on sys.saga_participant$ to admin;
grant all on sys.saga$ to admin;
grant all on sys.saga_participant_set$ to admin;

alter session set container=cdb1_pdb3;
--grant aq_administrator_role to admin;
grant connect,resource,unlimited tablespace to admin;
--grant execute on sys.dbms_saga_adm to admin;
--grant execute on sys.dbms_saga to admin;
grant saga_adm_role to admin;
grant saga_participant_role to admin;
grant saga_connect_role to admin;
grant all on sys.saga_message_broker$ to admin;
grant all on sys.saga_participant$ to admin;
grant all on sys.saga$ to admin;
grant all on sys.saga_participant_set$ to admin;

alter session set container=cdb1_pdb4;
--grant aq_administrator_role to admin;
grant connect,resource,unlimited tablespace to admin;
--grant execute on sys.dbms_saga_adm to admin;
--grant execute on sys.dbms_saga to admin;
grant saga_adm_role to admin;
grant saga_participant_role to admin;
grant saga_connect_role to admin;
grant all on sys.saga_message_broker$ to admin;
grant all on sys.saga_participant$ to admin;
grant all on sys.saga$ to admin;
grant all on sys.saga_participant_set$ to admin;