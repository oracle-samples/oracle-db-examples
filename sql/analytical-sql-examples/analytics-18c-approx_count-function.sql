REM   Script: 18c approx_count function
REM   Data analysis applications heavily use aggregate functions. Approximate query processing (available since Oracle Database 12c Release 1) aims to deliver faster results for these queries. The approximate results are not identical to the exact results but they are very close. New approximate SQL functions for rank, sum and count are now available for Top-N style queries.

By making use of approximate query processing, you can instantly improve the performance of existing analytic workloads and enable faster ad-hoc data exploration

drop table t purge;

create table t as  
select * from all_objects 
where owner in ('SYS','SYSTEM','PUBLIC','SCOTT','HR','SALES');

select owner, count(*)  
from t 
group by owner 
order by 1;

-- For the new approx_count functions, you must have a matching approx_rank function as part of the GROUP BY definition
select owner, approx_count(*)  
from t 
group by owner 
order by 1;

select owner, approx_count(*)  
from t 
group by owner 
having approx_rank(partition by owner order by approx_count(*) desc) <= 1 
order by 1;

select owner, approx_count(*) , approx_rank(partition by owner order by approx_count(*) desc) 
from t 
group by owner 
having approx_rank(partition by owner order by approx_count(*) desc) <= 1 
order by 1;

-- You can see the benefit of the restriction when you see that the partition by clause can be a subset of the group by aggregation columns.  Hence in this example, we get the top 8 ranked object types *per owner*
select owner, object_type, approx_count(*) , approx_rank(partition by owner order by approx_count(*) desc) 
from t 
group by owner, object_type 
having approx_rank(partition by owner order by approx_count(*) desc) <= 8 
order by 1;

