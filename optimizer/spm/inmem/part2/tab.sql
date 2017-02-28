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
for i in 1..1500
loop
insert into mysales values (i,i,'X',i);
end loop;
commit;
end;
/

begin
for i in 1..20000
loop
insert into mysales values (i+1500,1,'XXXXXXXXXXXXXX',i);
end loop;
commit;
end;
/

begin
for i in 1..2000000
loop
insert into mysales values (i+50000,-1,'XXXXXXXXXXX',i);
end loop;
commit;
end;
/

create index si on mysales(sale_type);

execute dbms_stats.gather_table_stats(ownname=>null,tabname=>'MYSALES',method_opt=>'for columns sale_type');

SELECT COLUMN_NAME, NOTES, HISTOGRAM 
FROM   USER_TAB_COL_STATISTICS 
WHERE  TABLE_NAME = 'MYSALES';
