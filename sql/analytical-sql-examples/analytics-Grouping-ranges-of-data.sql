REM   Script: Analytics - Grouping ranges of data
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script looks at the classical problem of identifying groups of data within a set of rows.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table LAB_SAMPLES;

drop sequence LAB_SAMPLES_SEQ;

create sequence LAB_SAMPLES_SEQ;

create table LAB_SAMPLES
 ( sample_id          int default LAB_SAMPLES_SEQ.NEXTVAL,
   date_taken  date
 );

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-02');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-03');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-04');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-07');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-08');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-09');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-10');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-14');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-15');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-16');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-19');

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-20');

select * from LAB_SAMPLES order by 2;

select
  date_taken,
  lag(date_taken) over ( order by date_taken) prev
from lab_samples
order by 1;

select
  date_taken,
  case
    when nvl(lag(date_taken) over (order by date_taken),date_taken) != date_taken-1
       then date_taken end loval
from lab_samples
order by 1;

select date_taken, max(loval) over (order by date_taken) loval
from (
select date_taken,
 case
   when nvl(lag(date_taken) over (order by date_taken),date_taken) != 
    date_taken-1 then date_taken end loval
from lab_samples )
order by 1;

select min(date_taken) range_start, max(date_taken) range_end
from (
  select date_taken,max(loval) over (order by date_taken) loval
  from (
    select date_taken,
       case
         when nvl(lag(date_taken) over (order by date_taken),date_taken) != 
           date_taken-1 then date_taken end loval
    from lab_samples))
group by loval
order by 1;

