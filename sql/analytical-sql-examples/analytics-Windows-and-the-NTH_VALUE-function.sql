REM   Script: Analytics - Windows and the NTH_VALUE function
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script is for deriving the nth_value from within a window.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table trips purge;

create table trips ( trip_date date, trip_count int );

insert into trips values (date '2014-07-01',21228);

insert into trips values (date '2014-07-02',26480);

insert into trips values (date '2014-07-03',21597);

insert into trips values (date '2014-07-04',14148);

insert into trips values (date '2014-07-05',10890);

insert into trips values (date '2014-07-06',11443);

insert into trips values (date '2014-07-07',18280);

insert into trips values (date '2014-07-08',25763);

insert into trips values (date '2014-07-09',27817);

insert into trips values (date '2014-07-10',30541);

insert into trips values (date '2014-07-11',28752);

insert into trips values (date '2014-07-12',25936);

insert into trips values (date '2014-07-13',21082);

insert into trips values (date '2014-07-14',27350);

insert into trips values (date '2014-07-15',33845);

insert into trips values (date '2014-07-16',28607);

insert into trips values (date '2014-07-17',30710);

insert into trips values (date '2014-07-18',29860);

insert into trips values (date '2014-07-19',25726);

insert into trips values (date '2014-07-20',21212);

insert into trips values (date '2014-07-21',23578);

insert into trips values (date '2014-07-22',29029);

insert into trips values (date '2014-07-23',34073);

insert into trips values (date '2014-07-24',32050);

insert into trips values (date '2014-07-25',29975);

insert into trips values (date '2014-07-26',27708);

insert into trips values (date '2014-07-27',22590);

insert into trips values (date '2014-07-28',23981);

insert into trips values (date '2014-07-29',27589);

insert into trips values (date '2014-07-30',30740);

insert into trips values (date '2014-07-31',33541);

insert into trips values (date '2014-08-01',32353);

insert into trips values (date '2014-08-02',28678);

insert into trips values (date '2014-08-03',23146);

insert into trips values (date '2014-08-04',24952);

insert into trips values (date '2014-08-05',28094);

insert into trips values (date '2014-08-06',30495);

insert into trips values (date '2014-08-07',32759);

insert into trips values (date '2014-08-08',30411);

insert into trips values (date '2014-08-09',26286);

insert into trips values (date '2014-08-10',20584);

insert into trips values (date '2014-08-11',22632);

insert into trips values (date '2014-08-12',29646);

insert into trips values (date '2014-08-13',29788);

insert into trips values (date '2014-08-14',30457);

insert into trips values (date '2014-08-15',28974);

insert into trips values (date '2014-08-16',26234);

insert into trips values (date '2014-08-17',21209);

insert into trips values (date '2014-08-18',21956);

insert into trips values (date '2014-08-19',24834);

insert into trips values (date '2014-08-20',27955);

insert into trips values (date '2014-08-21',32304);

insert into trips values (date '2014-08-22',29512);

insert into trips values (date '2014-08-23',27097);

insert into trips values (date '2014-08-24',22036);

insert into trips values (date '2014-08-25',22093);

insert into trips values (date '2014-08-26',24550);

insert into trips values (date '2014-08-27',27018);

insert into trips values (date '2014-08-28',28597);

insert into trips values (date '2014-08-29',27424);

insert into trips values (date '2014-08-30',23930);

insert into trips values (date '2014-08-31',23271);

insert into trips values (date '2014-09-01',19961);

insert into trips values (date '2014-09-02',28831);

insert into trips values (date '2014-09-03',32631);

insert into trips values (date '2014-09-04',38360);

insert into trips values (date '2014-09-05',42319);

insert into trips values (date '2014-09-06',40520);

insert into trips values (date '2014-09-07',30134);

insert into trips values (date '2014-09-08',30360);

insert into trips values (date '2014-09-09',34560);

insert into trips values (date '2014-09-10',35910);

insert into trips values (date '2014-09-11',36439);

insert into trips values (date '2014-09-12',39540);

insert into trips values (date '2014-09-13',43205);

insert into trips values (date '2014-09-14',28122);

insert into trips values (date '2014-09-15',29454);

insert into trips values (date '2014-09-16',36092);

insert into trips values (date '2014-09-17',35531);

insert into trips values (date '2014-09-18',40274);

insert into trips values (date '2014-09-19',41017);

insert into trips values (date '2014-09-20',38864);

insert into trips values (date '2014-09-21',28620);

insert into trips values (date '2014-09-22',28312);

insert into trips values (date '2014-09-23',30316);

insert into trips values (date '2014-09-24',31301);

insert into trips values (date '2014-09-25',38203);

insert into trips values (date '2014-09-26',37504);

insert into trips values (date '2014-09-27',39468);

insert into trips values (date '2014-09-28',29656);

insert into trips values (date '2014-09-29',29201);

insert into trips values (date '2014-09-30',33431);

commit


select * from trips;

select 
  trip_date,
  trip_count, 
    nth_value(trip_count,2) over (
       order by trip_count
       range between unbounded preceding and unbounded following ) as low_2
from trips
order by 1;

select 
  trip_date,
  trip_count, 
  round(100*
    trip_count /
    nth_value(trip_count,2) over (
       order by trip_count
       range between unbounded preceding and unbounded following )
    ,2) as pct_comparison
from trips
order by 1;

select 
  trip_date,
  trip_count, 
    nth_value(trip_count,2 from last) over (
       order by trip_count
       range between unbounded preceding and unbounded following ) as hi_2
from trips
order by 1;

drop table trips purge;

create table trips ( trip_date date, trip_count int );

insert into trips values (date '2014-07-01',21228);

insert into trips values (date '2014-07-02',26480);

insert into trips values (date '2014-07-03',21597);

insert into trips values (date '2014-07-04',14148);

insert into trips values (date '2014-07-05',10890);

insert into trips values (date '2014-07-06',11443);

insert into trips values (date '2014-07-07',18280);

insert into trips values (date '2014-07-08',25763);

insert into trips values (date '2014-07-09',27817);

insert into trips values (date '2014-07-10',30541);

insert into trips values (date '2014-07-11',28752);

insert into trips values (date '2014-07-12',25936);

insert into trips values (date '2014-07-13',21082);

insert into trips values (date '2014-07-14',27350);

insert into trips values (date '2014-07-15',33845);

insert into trips values (date '2014-07-16',28607);

insert into trips values (date '2014-07-17',30710);

insert into trips values (date '2014-07-18',29860);

insert into trips values (date '2014-07-19',25726);

insert into trips values (date '2014-07-20',21212);

insert into trips values (date '2014-07-21',23578);

insert into trips values (date '2014-07-22',29029);

insert into trips values (date '2014-07-23',34073);

insert into trips values (date '2014-07-24',32050);

insert into trips values (date '2014-07-25',29975);

insert into trips values (date '2014-07-26',27708);

insert into trips values (date '2014-07-27',22590);

insert into trips values (date '2014-07-28',23981);

insert into trips values (date '2014-07-29',27589);

insert into trips values (date '2014-07-30',30740);

insert into trips values (date '2014-07-31',33541);

insert into trips values (date '2014-08-01',32353);

insert into trips values (date '2014-08-02',28678);

insert into trips values (date '2014-08-03',23146);

insert into trips values (date '2014-08-04',24952);

insert into trips values (date '2014-08-05',28094);

insert into trips values (date '2014-08-06',30495);

insert into trips values (date '2014-08-07',32759);

insert into trips values (date '2014-08-08',30411);

insert into trips values (date '2014-08-09',26286);

insert into trips values (date '2014-08-10',20584);

insert into trips values (date '2014-08-11',22632);

insert into trips values (date '2014-08-12',29646);

insert into trips values (date '2014-08-13',29788);

insert into trips values (date '2014-08-14',30457);

insert into trips values (date '2014-08-15',28974);

insert into trips values (date '2014-08-16',26234);

insert into trips values (date '2014-08-17',21209);

insert into trips values (date '2014-08-18',21956);

insert into trips values (date '2014-08-19',24834);

insert into trips values (date '2014-08-20',27955);

insert into trips values (date '2014-08-21',32304);

insert into trips values (date '2014-08-22',29512);

insert into trips values (date '2014-08-23',27097);

insert into trips values (date '2014-08-24',22036);

insert into trips values (date '2014-08-25',22093);

insert into trips values (date '2014-08-26',24550);

insert into trips values (date '2014-08-27',27018);

insert into trips values (date '2014-08-28',28597);

insert into trips values (date '2014-08-29',27424);

insert into trips values (date '2014-08-30',23930);

insert into trips values (date '2014-08-31',23271);

insert into trips values (date '2014-09-01',19961);

insert into trips values (date '2014-09-02',28831);

insert into trips values (date '2014-09-03',32631);

insert into trips values (date '2014-09-04',38360);

insert into trips values (date '2014-09-05',42319);

insert into trips values (date '2014-09-06',40520);

insert into trips values (date '2014-09-07',30134);

insert into trips values (date '2014-09-08',30360);

insert into trips values (date '2014-09-09',34560);

insert into trips values (date '2014-09-10',35910);

insert into trips values (date '2014-09-11',36439);

insert into trips values (date '2014-09-12',39540);

insert into trips values (date '2014-09-13',43205);

insert into trips values (date '2014-09-14',28122);

insert into trips values (date '2014-09-15',29454);

insert into trips values (date '2014-09-16',36092);

insert into trips values (date '2014-09-17',35531);

insert into trips values (date '2014-09-18',40274);

insert into trips values (date '2014-09-19',41017);

insert into trips values (date '2014-09-20',38864);

insert into trips values (date '2014-09-21',28620);

insert into trips values (date '2014-09-22',28312);

insert into trips values (date '2014-09-23',30316);

insert into trips values (date '2014-09-24',31301);

insert into trips values (date '2014-09-25',38203);

insert into trips values (date '2014-09-26',37504);

insert into trips values (date '2014-09-27',39468);

insert into trips values (date '2014-09-28',29656);

insert into trips values (date '2014-09-29',29201);

insert into trips values (date '2014-09-30',33431);

commit


select * from trips;

select 
  trip_date,
  trip_count, 
    nth_value(trip_count,2) over (
       order by trip_count
       range between unbounded preceding and unbounded following ) as low_2
from trips
order by 1;

select 
  trip_date,
  trip_count, 
  round(100*
    trip_count /
    nth_value(trip_count,2) over (
       order by trip_count
       range between unbounded preceding and unbounded following )
    ,2) as pct_comparison
from trips
order by 1;

select 
  trip_date,
  trip_count, 
    nth_value(trip_count,2 from last) over (
       order by trip_count
       range between unbounded preceding and unbounded following ) as hi_2
from trips
order by 1;

