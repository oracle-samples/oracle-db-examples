Rem JDBCSampleData.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      JDBCSampleData.sql 
Rem
Rem    DESCRIPTION
Rem      This SQL script is for creating a new database user and a sample schema 
Rem      that JDBC code samples use. 
Rem    
Rem    MODIFIED   (MM/DD/YY)
Rem    nbsundar    04/06/18 - Created

Rem Create a new user "testuser" that will be used in all JDBC code samples
Rem Login as sysadmin before executing the script 
CREATE USER testuser IDENTIFIED BY testuser123;

Rem Grant connect and resource access to the new "testuser"
Rem so that the user can connect and create objects
GRANT CONNECT, RESOURCE TO testuser;

Rem Grant required access to the new "testuser"
GRANT UNLIMITED TABLESPACE TO testuser;

Rem Switch the current session to the new testuser session
ALTER SESSION SET CURRENT_SCHEMA=testuser;

Rem General DEPT table for other code samples 
CREATE TABLE DEPT
   (DEPTNO NUMBER(2) CONSTRAINT PK_DEPT PRIMARY KEY,
	DNAME VARCHAR2(14) ,
	LOC VARCHAR2(13) ) ;

Rem Populate the table DEPT with few records     
INSERT INTO DEPT VALUES(10,'ACCOUNTING','NEW YORK');
INSERT INTO DEPT VALUES(20,'RESEARCH','DALLAS');
INSERT INTO DEPT VALUES(30,'SALES','CHICAGO');
INSERT INTO DEPT VALUES(40,'OPERATIONS','BOSTON');

Rem General EMP table for other code samples 
CREATE TABLE EMP
   (EMPNO NUMBER(4) CONSTRAINT PK_EMP PRIMARY KEY,
	ENAME VARCHAR2(10),
	JOB VARCHAR2(9),
	MGR NUMBER(4),
	HIREDATE DATE,
	SAL NUMBER(7,2),
	COMM NUMBER(7,2),
	DEPTNO NUMBER(2) CONSTRAINT FK_DEPTNO REFERENCES DEPT);
    
Rem Populate the table EMP with few records 
INSERT INTO EMP VALUES(7369,'SMITH','CLERK',7902,to_date('17-12-1980','dd-mm-yyyy'),800,NULL,20);
INSERT INTO EMP VALUES(7499,'ALLEN','SALESMAN',7698,to_date('20-2-1981','dd-mm-yyyy'),1600,300,30);
INSERT INTO EMP VALUES(7521,'WARD','SALESMAN',7698,to_date('22-2-1981','dd-mm-yyyy'),1250,500,30);
INSERT INTO EMP VALUES(7566,'JONES','MANAGER',7839,to_date('2-4-1981','dd-mm-yyyy'),2975,NULL,20);
INSERT INTO EMP VALUES(7654,'MARTIN','SALESMAN',7698,to_date('28-9-1981','dd-mm-yyyy'),1250,1400,30);
INSERT INTO EMP VALUES(7698,'BLAKE','MANAGER',7839,to_date('1-5-1981','dd-mm-yyyy'),2850,NULL,30);
INSERT INTO EMP VALUES(7782,'CLARK','MANAGER',7839,to_date('9-6-1981','dd-mm-yyyy'),2450,NULL,10);
INSERT INTO EMP VALUES(7788,'SCOTT','ANALYST',7566,to_date('13-JUL-87')-85,3000,NULL,20);
INSERT INTO EMP VALUES(7839,'KING','PRESIDENT',NULL,to_date('17-11-1981','dd-mm-yyyy'),5000,NULL,10);
INSERT INTO EMP VALUES(7844,'TURNER','SALESMAN',7698,to_date('8-9-1981','dd-mm-yyyy'),1500,0,30);
INSERT INTO EMP VALUES(7876,'ADAMS','CLERK',7788,to_date('13-JUL-87')-51,1100,NULL,20);
INSERT INTO EMP VALUES(7900,'JAMES','CLERK',7698,to_date('3-12-1981','dd-mm-yyyy'),950,NULL,30);
INSERT INTO EMP VALUES(7902,'FORD','ANALYST',7566,to_date('3-12-1981','dd-mm-yyyy'),3000,NULL,20);
INSERT INTO EMP VALUES(7934,'MILLER','CLERK',7782,to_date('23-1-1982','dd-mm-yyyy'),1300,NULL,10);
    
Rem Used in the SQLXMLSample.java code sample
CREATE TABLE SQLXML_JDBC_SAMPLE (DOCUMENT XMLTYPE, ID NUMBER);

Rem Used in the PLSQLSample.java code sample 
CREATE TABLE PLSQL_JDBC_SAMPLE 
    (NUM NUMBER(4) NOT NULL, 
     NAME VARCHAR2(20) NOT NULL, 
     INSERTEDBY VARCHAR2(20));

Rem Used in LOBBasic.java code sample
CREATE TABLE LOB_JDBC_SAMPLE
   (LOB_ID INT NOT NULL, 
    BLOB_DATA BLOB, 
    CLOB_DATA CLOB, 
    NCLOB_DATA NCLOB);

Rem Used in DateTimeStampSample.java code sample
CREATE TABLE EMP_DATE_JDBC_SAMPLE
(EMP_ID INTEGER PRIMARY KEY, 
 DATE_OF_BIRTH DATE, 
 DATE_OF_JOINING TIMESTAMP WITH LOCAL TIME ZONE, 
 DATE_OF_RESIGNATION TIMESTAMP WITH TIME ZONE, 
 DATE_OF_LEAVING TIMESTAMP);
 
Rem Used in JSONBasicDemo.java code sample
CREATE TABLE JSON_EMP_JDBC_SAMPLE
  (EMP_ID RAW(16) NOT NULL PRIMARY KEY,
   DATE_LOADED TIMESTAMP WITH TIME ZONE,
   EMPLOYEE_DOCUMENT CLOB CONSTRAINT 
   ENSURE_JSON CHECK (EMPLOYEE_DOCUMENT IS JSON));
        
Rem Used in JSONBasicDemo.java code sample                
INSERT INTO JSON_EMP_JDBC_SAMPLE VALUES (SYS_GUID(), SYSTIMESTAMP, '{"employee_number": 1, "employee_name": "John Doe", "salary": 2000}');
INSERT INTO JSON_EMP_JDBC_SAMPLE VALUES (SYS_GUID(), SYSTIMESTAMP, '{"employee_number": 2, "employee_name": "Jane Doe", "salary": 2010}');
INSERT INTO JSON_EMP_JDBC_SAMPLE VALUES (SYS_GUID(), SYSTIMESTAMP, '{"employee_number": 3, "employee_name": "John Smith", "salary": 3000, "sons": [{"name": "Angie"}, {"name": "Linda"}]}');
INSERT INTO JSON_EMP_JDBC_SAMPLE VALUES (SYS_GUID(), SYSTIMESTAMP, '{"employee_number": 3, "employee_name": "Jane Williams", "salary": 1000, "sons": [{"name": "Rosie"}]}');   
    
Rem commit the changes to the database
commit;

Rem remove the tables for any clean up
Rem drop table SQLXML_JDBC_SAMPLE;
Rem drop table PLSQL_JDBC_SAMPLE;
Rem drop table LOB_JDBC_SAMPLE;
Rem drop table JSON_EMP_JDBC_SAMPLE;
Rem drop table EMP_DATE_JDBC_SAMPLE;
Rem drop table EMP;
Rem drop table DEPT;
