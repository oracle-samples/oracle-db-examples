--
-- Create a SALES table with data skew
-- and force the creation of a histogram
--
drop table sales;

create table sales (
 id number(10)
,txt varchar2(100)
,val number(10))
/

begin
for i in 1..20
loop
insert into sales values (i,'XX',i);
end loop;
commit;
end;
/

begin
for i in 1..600000
loop
insert into sales values (-1,'XX',i);
end loop;
commit;
end;
/

create index si on sales(id);

execute dbms_stats.gather_table_stats(ownname=>null,tabname=>'SALES',method_opt=>'for all indexed columns size 254');

