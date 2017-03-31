Rem InternalT4Driver.sql
Rem
Rem Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      InternalT4Driver.sql 
Rem
Rem    DESCRIPTION
Rem     SQL for invoking the method which connects to server side JDBC thin 
Rem     driver or server side Type 4 sriver.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    nbsundar    03/31/15 - Created
Rem    kmensah     03/31/15 - Contributor

connect / as sysdba

Rem Permissions for Connecting to another DB session via thin-driver in the server
Rem Most of these are network privileges
Rem Make sure to change the host name and IP:Port number
CALL dbms_java.grant_permission( 'HR','SYS:java.net.SocketPermission',
'slc07qwu', 'resolve');
CALL dbms_java.grant_permission( 'HR','SYS:java.net.SocketPermission',
 '10.244.140.89:5521', 'connect,resolve');
CALL dbms_java.grant_permission( 'HR','SYS:java.sql.SQLPermission', 
'setLog', '' );


Rem Compiling the sources in the server
connect hr/hr
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED InternalT4Driver_src AS
@ InternalT4Driver.java
/

show error

Rem A wrapper (a.k.a. Call Spec), to invoke Java
Rem function in the database from SQL, PL/SQL, and client applications
CREATE OR REPLACE PROCEDURE InternalT4Driver_proc AS 
LANGUAGE JAVA NAME 'InternalT4Driver.jrun ()';
/

Rem Running the sample
connect hr/hr
SET SERVEROUTPUT ON SIZE 10000 
CALL dbms_java.set_output (10000);

execute InternalT4Driver_proc;

