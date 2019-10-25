REM   Script: Optimizer Improvements for ANSI fetch first/offset queries
REM   19c contains a keenly awaited fix to the optimizer costing for for ANSI fetch first/offset queries. Now they can take advantage of an index scan + stopkey as per the older style order by/rownum syntax.

create table t as select * from all_objects  
where object_id is not null;

create index ix on t ( object_id );

explain plan for select * from t 
order by object_id desc 
fetch first 5 rows only


select * from dbms_xplan.display();

explain plan for 
select * from t 
order by object_id desc 
offset 5 rows fetch next 5 rows only


select * from dbms_xplan.display();

