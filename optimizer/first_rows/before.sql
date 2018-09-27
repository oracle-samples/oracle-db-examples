set pagesize 1000 linesize 350 trims on
column owner format a10
column edition_name format a10
column object_name format a20
column subobject_name format a20
set timing on
select * from   
( select *     
  from   t     
  order by object_id desc   ) 
where rownum <= 10; 

@plan

select * from
( select *
  from   t
  order by object_id desc   )
where rownum <= 10;

@plan
  
select * 
from   t     
order by object_id asc 
fetch first 10 rows only; 

@plan

select *
from   t
order by object_id asc
fetch first 10 rows only;

@plan

select *
from   t
order by object_id asc
offset 10 rows fetch first 10 rows only;

@plan
