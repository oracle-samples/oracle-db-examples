set linesize 200
set tab off
set pagesize 200
drop table mysales;

create table mysales (
 id number(10)
,sale_type number(10)
,txt varchar2(100)
,val number(10))
/

begin
for j in 1..20
loop
for i in 1..10000
loop
insert into mysales values ((i+200)*j,j,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',i);
end loop;
end loop;
commit;
end;
/

create index si on mysales(sale_type);

execute dbms_stats.gather_table_stats(ownname=>null,tabname=>'MYSALES');
