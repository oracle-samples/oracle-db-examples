Rem JavaStoredProcSample.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      JavaStoredProcSample.sql
Rem
Rem    DESCRIPTION
Rem      This SQL script is for creating a wrapper for a java stored procedure; 
REm      then calls it and displays the output.
REM 
REM Wrapper (a.k.a. Call Spec) for invoking JavaStoredProcSample.getEmpCountByDept(int) 
REM 

CREATE OR REPLACE FUNCTION GET_EMP_COUNT_BY_DEPT (dept_no NUMBER)
   RETURN NUMBER AS LANGUAGE JAVA
   NAME 'JavaStoredProcSample.getEmpCountByDept(int) return int';
/

REM 
REM Enable the output of GET_EMP_COUNT_BY_DEPT() then invoke it. 
REM 

set echo on 
set serveroutput on size 5000 
call dbms_java.set_output (5000); 

VARIABLE v NUMBER;
CALL GET_EMP_COUNT_BY_DEPT(20) INTO :v;
PRINT v

