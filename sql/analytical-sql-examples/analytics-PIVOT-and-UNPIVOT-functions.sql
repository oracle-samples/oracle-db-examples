REM   Script: Analytics - PIVOT and UNPIVOT functions
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script demonstrates the PIVOT and UNPIVOT functions.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

select to_char(trunc(s.time_id,'Q'),'MON') quarter,
       prod_category,
       count(*)
from sh.sales s,
     sh.products p
where s.prod_id = p.prod_id
and   s.time_Id >= date '2000-01-01'
and   s.time_Id < date '2001-01-01'
group by p.prod_category,
         to_char(trunc(s.time_id,'Q'),'MON')
order by 2,to_date(to_char(trunc(s.time_id,'Q'),'MON'),'MON');

select prod_category,jan,apr,jul,oct
from (
  select to_char(trunc(s.time_id,'Q'),'MON') quarter,
         prod_category
  from sh.sales s,
       sh.products p
  where s.prod_id = p.prod_id
  and   s.time_Id >= date '2000-01-01'
  and   s.time_Id < date '2001-01-01'
)
pivot ( count(*) for quarter in 
( 'JAN' as jan,'APR' as apr,'JUL' as jul,'OCT' as oct ) )
order by 1;

drop table pivoted_sales purge;

create table pivoted_sales as
select prod_category,jan,apr,jul,oct
from (
  select to_char(trunc(s.time_id,'Q'),'MON') quarter,
         prod_category
  from sh.sales s,
       sh.products p
  where s.prod_id = p.prod_id
  and   s.time_Id >= date '2000-01-01'
  and   s.time_Id < date '2001-01-01'
)
pivot ( count(*) for quarter in 
( 'JAN' as jan,'APR' as apr,'JUL' as jul,'OCT' as oct ) )
order by 1;

select prod_category, quarter, quantity
from pivoted_sales
unpivot
(  quantity for quarter in (JAN,APR,JUL,OCT) )
order by 1,to_date(quarter,'MON');

update pivoted_sales
set oct = null
where prod_category = 'Hardware';

commit


select prod_category, quarter, quantity
from pivoted_sales
unpivot
(  quantity for quarter in (JAN,APR,JUL,OCT) )
order by 1,to_date(quarter,'MON');

select prod_category, quarter, quantity
from pivoted_sales
unpivot include nulls
(  quantity for quarter in (JAN,APR,JUL,OCT) )
order by 1,to_date(quarter,'MON');

