REM   Script: Analytics - Dynamically sized windows
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script is using a PL/SQL function to create dynamic window range.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

select time_id,
       sum(amount_sold) sold_per_day
from   sh.sales
group by time_Id
order by 1;

create or replace
function LAST_CLOSE(p_close_date date)
return number is
begin
  return
    case to_char(p_close_date,'DY')
     when 'SUN' then 2
     when 'MON' then 3
     else 1
    end;
end;
/

select
  time_id,
  to_char(time_id,'DY') close_day,
  sum(sold_per_day) 
    over ( 
      order by time_id 
      range between LAST_CLOSE(time_id) preceding and 0 following) as close_off
from ( 
  select time_id,
         sum(amount_sold) sold_per_day
  from   sh.sales
  group by time_Id
  );

