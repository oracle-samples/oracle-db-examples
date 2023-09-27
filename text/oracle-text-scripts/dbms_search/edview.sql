--connect sys/oracle as sysdba

--drop user scott cascade;
--@utlsampl
--connect scott/tiger

exec dbms_search.drop_index  ('ed')
exec dbms_search.create_index('ed')

drop view empdept;

create view empdept (
  empno, ename, job, dname, deptno, loc,
  constraint ep_pk primary key(empno)
     rely disable novalidate,
  constraint ep_fk foreign key(deptno) references dept(deptno)
     disable novalidate
  )
  as
select empno, ename, job, dname, e.deptno, loc
from   emp e, dept d
where  e.deptno = d.deptno
/

exec dbms_search.add_source  ('ed', 'empdept')

select b.metadata."KEY"."EMPNO" from ed b where contains(data, 'cl%rk') > 0;

select ename, job, dname from
empdept, ed b
where empdept.empno = b.metadata."KEY"."EMPNO"
and contains(data, 'cl%rk') > 0;
