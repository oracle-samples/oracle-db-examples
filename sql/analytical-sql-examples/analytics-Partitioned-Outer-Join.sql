REM   Script: Analytics - Partitioned Outer Join
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script is demonstrates the partitioned outer join, a means via which to do a "grouped" outer join based on logical subsets of the data.  In the sample script, we perform a join on bookings for meetings room, partitioning the result set out for each room

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table bookings purge;

create table bookings ( hr int, room varchar2(10), who varchar2(10));

insert into bookings values(      8, 'Room2' ,     'PETE');

insert into bookings values(      9, 'Room1' ,     'JOHN');

insert into bookings values(     11, 'Room1' ,     'MIKE');

insert into bookings values(     14, 'Room2' ,     'JILL');

insert into bookings values(     15, 'Room2' ,     'JANE');

insert into bookings values(     16, 'Room1' ,     'SAM');

drop table hrs purge;

create table hrs ( hr int );

insert into hrs values ( 8);

insert into hrs values ( 9);

insert into hrs values (10);

insert into hrs values (11);

insert into hrs values (12);

insert into hrs values (13);

insert into hrs values (14);

insert into hrs values (15);

insert into hrs values (16);

select * from bookings;

select * from hrs;

select hrs.hr, t1.room, t1.who
from   hrs, bookings t1
where  hrs.hr = t1.hr(+)
order by 1;

select hrs.hr, t1.room, t1.who
from   bookings t1
partition by  (t1.room) 
right outer join hrs on (hrs.hr = t1.hr)
order by 1,2;

