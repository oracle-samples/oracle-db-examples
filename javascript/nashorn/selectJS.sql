REM
REM Calling SelectQuery (in select.js) using the Javax APi and wrappers (see Javax-wrapper.sql)
REM thru SQLDEMO procedure
REM
set serveroutput on
call dbms_java.set_output(5000);
call sqldemo('100');
REM You may use different parameter values.  