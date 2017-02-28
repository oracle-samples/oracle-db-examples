-- DISCLAIMER:
-- This script is provided for educational purposes only. It is 
-- NOT supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts initially 
-- on a test instance.
set echo off
connect / as sysdba

REM   To allow for re-execution of this script, 
REM   the user is first dropped, then created.
drop user aczm12c cascade;

set echo on
create user aczm12c identified by oracle_4U;
alter user aczm12c default tablespace users;
grant connect, dba to aczm12c;
