REM   Script: Analytics - More window clause examples
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script shows more window clause examples.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table water purge;

create table water ( name varchar2(30) primary key,
                     type varchar2(10),
                     square_km int );

insert into water(name,type,square_km) values ('Pacific Ocean','Ocean',155557000);

insert into water(name,type,square_km) values ('Atlantic Ocean','Ocean',76762000);

insert into water(name,type,square_km) values ('Indian Ocean','Ocean',68556000);

insert into water(name,type,square_km) values ('Southern Ocean','Ocean',20327000);

insert into water(name,type,square_km) values ('Arctic Ocean','Ocean',14056000);

insert into water(name,type,square_km) values ('Mediterranean Sea','Sea',2965800);

insert into water(name,type,square_km) values ('Caribbean Sea','Sea',2718200);

insert into water(name,type,square_km) values ('South China Sea','Sea',2319000);

insert into water(name,type,square_km) values ('Bering Sea','Sea',2291900);

insert into water(name,type,square_km) values ('Gulf of Mexico','Gulf',1592800);

insert into water(name,type,square_km) values ('Okhotsk Sea','Sea',1589700);

insert into water(name,type,square_km) values ('East China Sea','Sea',1249200);

insert into water(name,type,square_km) values ('Hudson Bay','Bay',1232300);

insert into water(name,type,square_km) values ('Japan Sea','Sea',1007800);

insert into water(name,type,square_km) values ('Andaman Sea','Sea',797700);

insert into water(name,type,square_km) values ('North Sea','Sea',575200);

insert into water(name,type,square_km) values ('Red Sea','Sea',438000);

insert into water(name,type,square_km) values ('Baltic Sea','Sea',422200);

commit


select * 
from water
order by 3 desc;

select name, type, square_km,
       sum(square_km) over ( 
          partition by type
          order by square_km desc 
          rows between 1 preceding and 1 following
) as "3_ROW"
from water
order by decode(type,'Ocean',1,'Sea',2,3), square_km desc;

