SET ECHO OFF
/*
** Copyright (c) 2023 Oracle and/or its affiliates
** The Universal Permissive License (UPL), Version 1.0
**
** Subject to the condition set forth below, permission is hereby granted to any
** person obtaining a copy of this software, associated documentation and/or data
** (collectively the "Software"), free of charge and under any and all copyright
** rights in the Software, and any and all patent rights owned or freely
** licensable by each licensor hereunder covering either (i) the unmodified
** Software as contributed to or provided by such licensor, or (ii) the Larger
** Works (as defined below), to deal in both
**
** (a) the Software, and
** (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
** one is included with the Software (each a "Larger Work" to which the Software
** is contributed by such licensors),
**
** without restriction, including without limitation the rights to copy, create
** derivative works of, display, perform, and distribute the Software and make,
** use, sell, offer for sale, import, export, have made, and have sold the
** Software and the Larger Work(s), and to sublicense the foregoing rights on
** either these or other terms.
**
** This license is subject to the following condition:
** The above copyright notice and either this complete permission notice or at
** a minimum a reference to the UPL must be included in all copies or
** substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
** SOFTWARE.
*/

--    TITLE
--      Working with Oracle Database 23c Schema Privileges
--
--    DESCRIPTION
--      This tutorial script walks you through examples of working with
--      schema-level privileges
--
--    PREREQUISITES
--      Ensure that you have Oracle database 23c or higher installed and running on a
--      port. Ensure that the compatible parameter is set to at least 23.0.0.0.
--
--    USAGE
--      Connect to the database as a database adminstrator (or any user with permissions 
--       to create users and grant tablespace privileges) user and run this
--      script. A demo user (janus) can be created using this statement:
--       GRANT create user, create session, unlimited tablespace TO janus IDENTIFIED BY ORacle__123 with admin option;
--       
--
--    NOTES
--      Oracle Database 23c Free - Developer Release is the first release of
--      the next-generation Oracle Database, allowing developers a head-start
--      on building applications with innovative 23c features that simplify
--      development of modern data-driven apps. The entire feature set of
--      Oracle Database 23c is planned to be generally available within the
--      next 12 months.
--
--      Please go through the database security documentation
--      (https://docs.oracle.com/en/database/oracle/oracle-database/23/dbseg/index.html)
--      to learn more about new security features in Database 23c
--      Oracle CloudWorld 2022 keynote - https://www.youtube.com/watch?v=e8-jBkO1NqY&t=17s


SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
SET LONG 20000
col username format a30
col privilege format a30
col schema format a30
cle scre

prompt
prompt ** Working with Schema-level privileges**
prompt
prompt During this tutorial you will create two users. What password should 
prompt we use for those two users?
prompt Enter the password to use &&PASSWORD
prompt
prompt During this tutorial we will connect and reconnect to 
prompt this database several times. Which TNS Alias should we use 
prompt for the connection?  &&DATABASE_ALIAS
prompt
prompt Lets test that the password you gave us meets your own 
prompt password complexity standards by creating a dummy user.
prompt What username should we use? &&DUMMY_USER_NAME

create user &&DUMMY_USER_NAME identified by &&PASSWORD;
prompt  If the create user statement failed, please either adjust the username 
prompt  to an unused username, or the password to meet your systems 
prompt password complexity rules. Click enter to continue, <ctrl>-c to exit and 
pause retry.
drop user &&DUMMY_USER_NAME;

-- Do cleanup for previous run (if any).
--
select username, count(*) from dba_users a left outer join dba_objects b on b.owner=a.username where a.username in ('APP_SCHEMA', 'APP_USER') group by username;
prompt
prompt **If you do NOT want to drop these two users and all objects 
prompt in their schemas, use <ctrl>-c to exit this script now!
pause  Press enter to continue, or <ctrl>-c to exit without dropping these users

drop user APP_SCHEMA cascade;
drop user APP_USER;


prompt ==================================================
prompt Step 1: Create users and a few test tables 
prompt ==================================================
pause  Press enter to continue,

-- Create users and a few tables for the test.
--
CREATE USER APP_SCHEMA identified by &&PASSWORD;
CREATE USER APP_USER identified by &&PASSWORD;
grant create session to APP_USER;
grant create session, create table, unlimited tablespace to APP_SCHEMA;


CREATE TABLE APP_SCHEMA.DATA1
  (name    VARCHAR2(255));
  
INSERT INTO APP_SCHEMA.DATA1 VALUES ('Bob');
INSERT INTO APP_SCHEMA.DATA1 VALUES ('Jane');

CREATE TABLE APP_SCHEMA.DATA2
  (city    VARCHAR2(255));
  
INSERT INTO APP_SCHEMA.DATA2 VALUES ('London');
INSERT INTO APP_SCHEMA.DATA2 VALUES ('Dubai');
COMMIT;

prompt ==================================================
prompt Step 2: Connect as APP_USER and verify you can not see data in APP_SCHEMA tables
prompt ==================================================
prompt
prompt
pause Press enter to continue
prompt
prompt connect APP_USER@DATABASE_ALIAS
connect APP_USER/&&PASSWORD@&DATABASE_ALIAS
set echo on
select * from APP_SCHEMA.DATA1;
select * from APP_SCHEMA.DATA2;
set echo off


prompt ==================================================
prompt APP_USER could not select from the APP_SCHEMA tables because
prompt the user had no privileges on the objects or schema
pause Press enter to continue
prompt
prompt Step 3: Grant schema privileges to APP_USER
prompt Now we will switch to APP_SCHEMA 
prompt and give APP_USER permission view data in APP_SCHEMA
prompt ==================================================
prompt
prompt connect APP_SCHEMA@DATABASE_ALIAS
connect APP_SCHEMA/&&PASSWORD@&&DATABASE_ALIAS
prompt **********
prompt ********** Pay close attention to the next statement - THIS is the new feature!
prompt **********
set echo on
grant select any table on schema app_schema to app_user;
set echo off

prompt ==================================================
prompt APP_USER should now be able to see all data in APP_SCEMA
prompt
pause Press enter to continue
prompt
prompt Step 4: Test the schema privileges
prompt Lets verify that APP_USER can now view data in APP_SCHEMA
prompt ==================================================
prompt
prompt connect APP_USER@DATABASE_ALIAS
connect APP_USER/&&PASSWORD@&DATABASE_ALIAS
set echo on
select * from session_schema_privs;
prompt
prompt Notice that APP_USER has session privileges 
prompt to SELECT ANYT TABLE from the APP_SCHEMA schema
pause Press enter to continue
select * from APP_SCHEMA.DATA1;
select * from APP_SCHEMA.DATA2;
set echo off

prompt ==================================================
prompt Here comes the good part - when APP_SCHEMA adds a new table
prompt APP_USER should automatically have access to the new table
prompt
pause Press enter to continue
prompt
prompt Step 5: Create a new table in APP_SCHEMA
prompt Now we will switch to APP_SCHEMA and create a new table. We do not 
prompt need to worry about granting APP_USER permission to select from the table
prompt because we have permission to select from the entire schema
prompt ==================================================
prompt
prompt connect APP_SCHEMA@DATABASE_ALIAS
connect APP_SCHEMA/&&PASSWORD@&DATABASE_ALIAS
set echo on
CREATE TABLE APP_SCHEMA.DATA3
  (country    VARCHAR2(255));
  
INSERT INTO APP_SCHEMA.DATA3 VALUES ('United Kingdom');
INSERT INTO APP_SCHEMA.DATA3 VALUES ('United Arab Emirates');
COMMIT;
set echo off

prompt ==================================================
pause Press enter to continue
prompt
prompt Step 6: Test the schema privileges again
prompt Lets verify that APP_USER can see the new table added to APP_SCHEMA
prompt ==================================================

prompt
prompt connect APP_USER@DATABASE_ALIAS
connect APP_USER/&&PASSWORD@&DATABASE_ALIAS
set echo on
select * from APP_SCHEMA.DATA3;
set echo off


prompt
prompt
prompt ==================================================
prompt  As you have seen, the new schema-level privileges make it easy to 
prompt  grant access to ALL of an applications data and objects, and as 
prompt  new objects are added to the schema there is no need to update 
prompt  grants for those new objects
prompt ==================================================
prompt


