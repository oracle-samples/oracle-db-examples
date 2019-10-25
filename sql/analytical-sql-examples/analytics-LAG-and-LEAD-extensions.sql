REM   Script: Analytics - LAG and LEAD extensions
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script shows how to use the IGNORE NULLS extensions to lag and lead.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table external_emp;

create table external_emp (
SEQ int,
EMPNO    NUMBER(4)    ,
ENAME             VARCHAR2(10) ,
JOB               VARCHAR2(9)  ,
MGR               NUMBER(4)    ,
HIREDATE          DATE         ,
SAL               NUMBER(7,2)  ,
COMM              NUMBER(7,2)  ,
DEPTNO            NUMBER(2)    
);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (1,7782,'CLARK','MANAGER',7839,to_date('09/JUN/81','DD/MON/RR'),2450,null,10);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (2,7839,'KING','PRESIDENT',null,to_date('17/NOV/81','DD/MON/RR'),5000,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (3,7934,'MILLER','CLERK',7782,to_date('23/JAN/82','DD/MON/RR'),1300,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (4,7369,'SMITH','CLERK',7902,to_date('17/DEC/80','DD/MON/RR'),800,null,20);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (5,7876,'ADAMS','CLERK',7788,to_date('12/JAN/83','DD/MON/RR'),1100,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (6,7902,'FORD','ANALYST',7566,to_date('03/DEC/81','DD/MON/RR'),3000,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7,7566,'JONES','MANAGER',7839,to_date('02/APR/81','DD/MON/RR'),2975,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (8,7788,'SCOTT','ANALYST',7566,to_date('09/DEC/82','DD/MON/RR'),3000,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (9,7499,'ALLEN','SALESMAN',7698,to_date('20/FEB/81','DD/MON/RR'),1600,300,30);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (10,7521,'WARD','SALESMAN',7698,to_date('22/FEB/81','DD/MON/RR'),1250,500,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (11,7654,'MARTIN','SALESMAN',7698,to_date('28/SEP/81','DD/MON/RR'),1250,1400,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (12,7698,'BLAKE','MANAGER',7839,to_date('01/MAY/81','DD/MON/RR'),2850,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (13,7844,'TURNER','SALESMAN',7698,to_date('08/SEP/81','DD/MON/RR'),1500,null,null);

insert into external_emp (SEQ,EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (14,7900,'JAMES','CLERK',7698,to_date('03/DEC/81','DD/MON/RR'),950,null,null);

commit


select empno, ename, job, hiredate, sal , deptno
from external_emp 
order by seq;

select empno, ename, job, hiredate, sal , 
       nvl(deptno, lag(deptno) over (order by SEQ))  deptno
from external_emp 
order by seq;

select empno, ename, job, hiredate, sal , 
       nvl(deptno, lag(deptno IGNORE NULLS) over (order by SEQ))  deptno
from external_emp 
order by seq;

