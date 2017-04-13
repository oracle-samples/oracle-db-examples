REM
REM Script for running hello.js in the database
REM
set serveroutput on
call dbms_java.set_output(20000);
call dbms_javascript.run("hello.js");
 
