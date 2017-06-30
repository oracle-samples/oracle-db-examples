REM
REM Wrapper (a.k.a. Call Spec) for invoking testSODA.main()
REM
create or replace procedure testSODA as
language java name 'testSODA.main(java.lang.String[])';
/
REM
REM Enable the output of testSODA(); then invoke it.
REM
set serveroutput on
call dbms_java.set_output(2000);
call testSODA();
exit;