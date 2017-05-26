REM
REM Enable the output of SQL or PL/SQL calls then invoke testSODA.js
REM
set serveroutput on
call dbms_java.set_output(2000);
call dbms_javascript.run('testSODA.js');
exit;
