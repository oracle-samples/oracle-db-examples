CLEAR SCREEN
CONNECT Sys/oracle@x/noncdb AS SYSDBA
declare
  User_Doesnt_Exist exception;
  pragma Exception_Init(User_Doesnt_Exist, -01918);
begin
  execute immediate 'drop user Usr cascade';
exception when User_Doesnt_Exist then null;
end;
/
grant
  Create Session,
  Create Procedure
to Usr identified by p
/
grant Execute on Sys.DBMS_Lock to Usr
/
CONNECT Usr/p@x/noncdb
alter session set Plsql_Warnings = 'Error:All'
/

create or replace procedure P authid definer is
  n pls_integer := 0;
begin
  Dbms_Output.Put_Line (Chr(10)||Rpad ('-',30,'-'));
  Dbms_Output.Put_Line ('starting'||Chr(10));
  for j in 1..10 loop    
    for k in 1..5 loop
      n := n+1;
      Dbms_Output.Put (Lpad (n, 5));
    end loop;
    Dbms_Output.Put_Line (Lpad (To_Char (Sysdate, 'hh24:mi:ss'), 10));
    Dbms_Lock.Sleep (2);
  end loop;
  Dbms_Output.Put_Line (Chr(10)||'Done'||Chr(10));
end P;
/
SHOW ERRORS

SET SERVEROUTPUT ON SIZE 1000000 FORMAT WRAPPED
call P()
/

SET SERVEROUTPUT OFF
begin
  Dbms_Output.Enable ('localhost', 1599, 'WE8ISO8859P1');
end;
/
call P()
/

declare
  -- ORA-01792: maximum number of columns in a table or view is 1000
  nof_columns constant pls_integer := 1000;

  procedure P (t in varchar2) is
    begin Dbms_Output.Put_Line (t); end P;
begin
  P ('drop table t');
  P ('/');
  P ('create table t (');
  for j in 1..(nof_columns-1) loop
    P (Lpad('a'||To_Char(j)||' integer,', 15));
  end loop;
  P (Lpad('a0 integer)', 15));
  P ('/');
end;
/
SET SERVEROUTPUT OFF
/*
@C:\bllewell_Data\Original\Plsql_Pm\Streaming_Dbms_Output\Spool_Files\Spool.txt
*/
