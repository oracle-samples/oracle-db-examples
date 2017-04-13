Rem SalaryHikeSP.sql
Rem
Rem Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      SalaryHikeSP.sql 
Rem
Rem    DESCRIPTION
Rem       SQL for invoking the method which gets a server side connection to
Rem      internal T2 Driver
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    nbsundar    03/23/15 - Created
Rem    kmensah     03/23/15 - Contributor

REM Reads the content of the Java source from SalaryHikeSP.java 
REM then compiles it 
connect hr/hr

CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED SalaryHikeSP_src AS
@SalaryHikeSP.java
/

REM Check for errors
show error
  
REM Create a PL/SQL wrapper
create or replace package refcur_pkg as
  TYPE EmpCurTyp IS REF CURSOR;
  function incrementsalary(percent IN NUMBER) return EmpCurTyp;
end refcur_pkg;
/
show errors;

create or replace package body refcur_pkg as  
function incrementsalary(percent IN NUMBER) return EmpCurTyp
 as language java 
 name 'SalaryHikeSP.incrementSalary(int) returns java.sql.ResultSet';

end refcur_pkg;
/

show error

/   

-- Running the sample
--- connect hr/hr
--- set serveroutput on
--- call dbms_java.set_output(50000);

---declare
  ---type EmpCur IS REF CURSOR;
  ---rc EmpCur;
  --employee employees%ROWTYPE;
--begin   
  --rc := refcur_pkg.incrementsalary(5);   
  --LOOP
  	--fetch rc into employee;
  	--exit when rc%notfound;
  	--dbms_output.put_line(' Name = ' || employee.FIRST_NAME || ' Salary = ' || employee.SALARY);
  --end loop;
--close rc;
--end;
--/
--show error;
--/



