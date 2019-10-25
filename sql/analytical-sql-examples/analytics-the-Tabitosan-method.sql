REM   Script: Analytics - the Tabitosan method
REM   Example of the tabitosan method at the granularity of minutes rather than days.

alter session set nls_date_format = 'dd/mm/yyyy hh24:mi:ss';

drop table LAB_SAMPLES purge;

drop sequence LAB_SAMPLES_SEQ purge;

create sequence LAB_SAMPLES_SEQ;

create table LAB_SAMPLES 
 ( sample_id          int default LAB_SAMPLES_SEQ.NEXTVAL, 
   date_taken  date 
 );

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01' + 123/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01' + 124/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01' + 125/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01' + 126/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01' + 567/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01' + 568/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-01' + 569/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-02' + 123/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-02' + 124/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-02' + 456/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-02' + 789/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-04' + 345/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-04' + 346/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-04' + 347/1440);

insert into LAB_SAMPLES ( date_taken) values (date '2015-12-04' + 789/1440);

select * from LAB_SAMPLES order by 2;

select date_taken, 
       row_number() over(order by date_taken)/1440 as rn 
       from LAB_SAMPLES 
order by 1;

select date_taken, 
       date_taken-row_number() over(order by date_taken)/1440 as delta 
       from LAB_SAMPLES 
order by 1;

select min(date_taken) date_from, 
       max(date_taken) date_to, 
       count(*) num_samples 
from ( 
  select date_taken, 
         date_taken-row_number() over(order by date_taken)/1440 as delta 
         from LAB_SAMPLES 
     ) 
group by delta 
order by 1;

