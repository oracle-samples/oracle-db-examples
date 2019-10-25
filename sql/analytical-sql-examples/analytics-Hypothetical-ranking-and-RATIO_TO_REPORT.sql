REM   Script: Analytics - Hypothetical ranking and RATIO_TO_REPORT
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script is the hypothetical RANK function, and the RATIO_TO_REPORT function.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table emp;

create table emp (
EMPNO    NUMBER(4)    ,
ENAME             VARCHAR2(10) ,
JOB               VARCHAR2(9)  ,
MGR               NUMBER(4)    ,
HIREDATE          DATE         ,
SAL               NUMBER(7,2)  ,
COMM              NUMBER(7,2)  ,
DEPTNO            NUMBER(2)    
);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7369,'SMITH','CLERK',7902,to_date('17/DEC/80','DD/MON/RR'),800,null,20);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7499,'ALLEN','SALESMAN',7698,to_date('20/FEB/81','DD/MON/RR'),1600,300,30);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7521,'WARD','SALESMAN',7698,to_date('22/FEB/81','DD/MON/RR'),1250,500,30);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7566,'JONES','MANAGER',7839,to_date('02/APR/81','DD/MON/RR'),2975,null,20);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7654,'MARTIN','SALESMAN',7698,to_date('28/SEP/81','DD/MON/RR'),1250,1400,30);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7698,'BLAKE','MANAGER',7839,to_date('01/MAY/81','DD/MON/RR'),2850,null,30);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7782,'CLARK','MANAGER',7839,to_date('09/JUN/81','DD/MON/RR'),2450,null,10);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7788,'SCOTT','ANALYST',7566,to_date('09/DEC/82','DD/MON/RR'),3000,null,20);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7839,'KING','PRESIDENT',null,to_date('17/NOV/81','DD/MON/RR'),5000,null,10);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7844,'TURNER','SALESMAN',7698,to_date('08/SEP/81','DD/MON/RR'),1500,null,30);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7876,'ADAMS','CLERK',7788,to_date('12/JAN/83','DD/MON/RR'),1100,null,20);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7900,'JAMES','CLERK',7698,to_date('03/DEC/81','DD/MON/RR'),950,null,30);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7902,'FORD','ANALYST',7566,to_date('03/DEC/81','DD/MON/RR'),3000,null,20);

Insert into emp (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO) values (7934,'MILLER','CLERK',7782,to_date('23/JAN/82','DD/MON/RR'),1300,null,10);

commit


select empno, ename, job, hiredate, sal , deptno
from emp 
order by deptno, hiredate;

select empno, ename, job, hiredate, sal,deptno,
       rank() OVER (order by hiredate) as hire_seq
from emp 
order by deptno, hiredate;

select 
  deptno, 
  rank(date '1981-10-01') 
    within group (order by hiredate) as hypo_hire_seq
from emp 
group by deptno
order by 1;

select
        empno,
        ename,
        sal,
        100*ratio_to_report(sal) over () as pct
from emp;

