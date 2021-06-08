REM   Script: Analytics - The RANGE options for windows
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script demonstrates the RANGE option for the windowing clause.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table tweets purge;

create table tweets ( 
  dte date primary key,
  tweet_millions number(16,6)
  );

insert into tweets values (to_date('01-JAN-06','dd-mon-rr'),0.000001);

insert into tweets values (to_date('01-FEB-06','dd-mon-rr'),0.000387);

insert into tweets values (to_date('01-MAR-06','dd-mon-rr'),0.000773);

insert into tweets values (to_date('01-APR-06','dd-mon-rr'),0.00116);

insert into tweets values (to_date('01-JUN-06','dd-mon-rr'),0.001932);

insert into tweets values (to_date('01-JUL-06','dd-mon-rr'),0.002318);

insert into tweets values (to_date('01-SEP-06','dd-mon-rr'),0.003091);

insert into tweets values (to_date('01-OCT-06','dd-mon-rr'),0.003477);

insert into tweets values (to_date('01-DEC-06','dd-mon-rr'),0.004249);

insert into tweets values (to_date('01-JAN-07','dd-mon-rr'),0.005);

insert into tweets values (to_date('01-FEB-07','dd-mon-rr'),0.027565);

insert into tweets values (to_date('01-MAR-07','dd-mon-rr'),0.05013);

insert into tweets values (to_date('01-APR-07','dd-mon-rr'),0.072694);

insert into tweets values (to_date('01-JUN-07','dd-mon-rr'),0.117824);

insert into tweets values (to_date('01-JUL-07','dd-mon-rr'),0.140389);

insert into tweets values (to_date('01-SEP-07','dd-mon-rr'),0.185518);

insert into tweets values (to_date('01-OCT-07','dd-mon-rr'),0.208083);

insert into tweets values (to_date('01-NOV-07','dd-mon-rr'),0.230648);

insert into tweets values (to_date('01-DEC-07','dd-mon-rr'),0.253213);

insert into tweets values (to_date('01-JAN-08','dd-mon-rr'),0.3);

insert into tweets values (to_date('01-FEB-08','dd-mon-rr'),0.473757);

insert into tweets values (to_date('01-MAR-08','dd-mon-rr'),0.647514);

insert into tweets values (to_date('01-APR-08','dd-mon-rr'),0.821271);

insert into tweets values (to_date('01-JUN-08','dd-mon-rr'),1.168785);

insert into tweets values (to_date('01-JUL-08','dd-mon-rr'),1.342543);

insert into tweets values (to_date('01-SEP-08','dd-mon-rr'),1.690057);

insert into tweets values (to_date('01-OCT-08','dd-mon-rr'),1.863814);

insert into tweets values (to_date('01-NOV-08','dd-mon-rr'),2.037571);

insert into tweets values (to_date('01-DEC-08','dd-mon-rr'),2.211328);

insert into tweets values (to_date('01-JAN-09','dd-mon-rr'),2.5);

insert into tweets values (to_date('01-FEB-09','dd-mon-rr'),4.57);

insert into tweets values (to_date('01-MAR-09','dd-mon-rr'),6.64);

insert into tweets values (to_date('01-APR-09','dd-mon-rr'),8.71);

insert into tweets values (to_date('01-JUN-09','dd-mon-rr'),12.85);

insert into tweets values (to_date('01-AUG-09','dd-mon-rr'),16.99);

insert into tweets values (to_date('01-SEP-09','dd-mon-rr'),19.05);

insert into tweets values (to_date('01-OCT-09','dd-mon-rr'),21.12);

insert into tweets values (to_date('01-DEC-09','dd-mon-rr'),25.26);

insert into tweets values (to_date('01-JAN-10','dd-mon-rr'),30);

insert into tweets values (to_date('01-FEB-10','dd-mon-rr'),31.54);

insert into tweets values (to_date('01-MAR-10','dd-mon-rr'),33.08);

insert into tweets values (to_date('01-APR-10','dd-mon-rr'),34.63);

insert into tweets values (to_date('01-MAY-10','dd-mon-rr'),36.17);

insert into tweets values (to_date('01-JUN-10','dd-mon-rr'),37.71);

insert into tweets values (to_date('01-JUL-10','dd-mon-rr'),39.25);

insert into tweets values (to_date('01-AUG-10','dd-mon-rr'),40.79);

insert into tweets values (to_date('01-SEP-10','dd-mon-rr'),42.34);

insert into tweets values (to_date('01-OCT-10','dd-mon-rr'),43.88);

insert into tweets values (to_date('01-NOV-10','dd-mon-rr'),45.42);

insert into tweets values (to_date('01-DEC-10','dd-mon-rr'),46.96);

insert into tweets values (to_date('01-JAN-11','dd-mon-rr'),50);

insert into tweets values (to_date('01-FEB-11','dd-mon-rr'),53.87);

insert into tweets values (to_date('01-MAR-11','dd-mon-rr'),57.74);

insert into tweets values (to_date('01-APR-11','dd-mon-rr'),61.61);

insert into tweets values (to_date('01-MAY-11','dd-mon-rr'),65.47);

insert into tweets values (to_date('01-JUN-11','dd-mon-rr'),69.34);

insert into tweets values (to_date('01-JUL-11','dd-mon-rr'),73.21);

insert into tweets values (to_date('01-AUG-11','dd-mon-rr'),77.08);

insert into tweets values (to_date('01-SEP-11','dd-mon-rr'),80.95);

insert into tweets values (to_date('01-OCT-11','dd-mon-rr'),84.82);

insert into tweets values (to_date('01-NOV-11','dd-mon-rr'),88.68);

insert into tweets values (to_date('01-DEC-11','dd-mon-rr'),92.55);

insert into tweets values (to_date('01-JAN-12','dd-mon-rr'),100);

insert into tweets values (to_date('01-FEB-12','dd-mon-rr'),108.1);

insert into tweets values (to_date('01-MAR-12','dd-mon-rr'),116.21);

insert into tweets values (to_date('01-APR-12','dd-mon-rr'),124.31);

insert into tweets values (to_date('01-MAY-12','dd-mon-rr'),132.41);

insert into tweets values (to_date('01-JUN-12','dd-mon-rr'),140.52);

insert into tweets values (to_date('01-JUL-12','dd-mon-rr'),148.62);

insert into tweets values (to_date('01-SEP-12','dd-mon-rr'),164.83);

insert into tweets values (to_date('01-OCT-12','dd-mon-rr'),172.93);

insert into tweets values (to_date('01-NOV-12','dd-mon-rr'),181.03);

insert into tweets values (to_date('01-DEC-12','dd-mon-rr'),189.13);

insert into tweets values (to_date('01-JAN-13','dd-mon-rr'),200);

insert into tweets values (to_date('01-FEB-13','dd-mon-rr'),204.13);

insert into tweets values (to_date('01-MAR-13','dd-mon-rr'),208.26);

insert into tweets values (to_date('01-MAY-13','dd-mon-rr'),216.52);

insert into tweets values (to_date('01-JUN-13','dd-mon-rr'),220.64);

insert into tweets values (to_date('01-AUG-13','dd-mon-rr'),228.9);

insert into tweets values (to_date('01-SEP-13','dd-mon-rr'),233.03);

insert into tweets values (to_date('01-OCT-13','dd-mon-rr'),237.16);

insert into tweets values (to_date('01-DEC-13','dd-mon-rr'),245.42);

insert into tweets values (to_date('01-JAN-14','dd-mon-rr'),250);

insert into tweets values (to_date('01-MAR-14','dd-mon-rr'),264.45);

insert into tweets values (to_date('01-APR-14','dd-mon-rr'),271.68);

insert into tweets values (to_date('01-MAY-14','dd-mon-rr'),278.91);

insert into tweets values (to_date('01-JUN-14','dd-mon-rr'),286.13);

insert into tweets values (to_date('01-AUG-14','dd-mon-rr'),300.59);

insert into tweets values (to_date('01-SEP-14','dd-mon-rr'),307.81);

insert into tweets values (to_date('01-OCT-14','dd-mon-rr'),315.04);

insert into tweets values (to_date('01-DEC-14','dd-mon-rr'),329.49);

insert into tweets values (to_date('01-JAN-15','dd-mon-rr'),340);

insert into tweets values (to_date('01-APR-15','dd-mon-rr'),376.6);

insert into tweets values (to_date('01-MAY-15','dd-mon-rr'),388.8);

insert into tweets values (to_date('01-JUL-15','dd-mon-rr'),413.2);

insert into tweets values (to_date('01-AUG-15','dd-mon-rr'),425.41);

insert into tweets values (to_date('01-OCT-15','dd-mon-rr'),449.81);

insert into tweets values (to_date('01-NOV-15','dd-mon-rr'),462.01);

insert into tweets values (to_date('01-DEC-15','dd-mon-rr'),474.21);

commit


select 
  dte,
  tweet_millions
from tweets
order by dte;

select  dte, tweet_millions,
  round(
    avg(tweet_millions) over
         ( order by dte
           range between interval '6' month preceding and current row )) mov_avg
from tweets
order by dte;

