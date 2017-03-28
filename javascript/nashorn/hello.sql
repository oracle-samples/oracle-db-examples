REM
REM Script for running hello.js in the database
REM
SQL>set serveroutput on
SQL>call dbms_java.set_output(20000);
SQL>call dbms_javascript.run("hello.js");
 