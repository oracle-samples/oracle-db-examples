set echo on

alter session set events '30579 trace name context forever, level 268435456';

drop table testtmp;

create table testtmp (id number, text varchar2(80))
partition by range (id)
( partition testp1 values less than  (  100000 ),
  partition testp2 values less than  ( 200000 ),
  partition testp3 values less than ( maxvalue ) 
);


begin
  for i in 1..300000 loop
    insert into testtmp values (i, 'hello'||i);
  end loop;
end;
/

exec ctx_ddl.drop_preference  ('mystorage')
exec ctx_ddl.create_preference('mystorage', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystorage', 'SMALL_R_ROW', 'T')

create index testtmpindex on testtmp(text) 
indextype is ctxsys.context
local
parameters ('storage mystorage');

select table_name from user_tables where table_name like 'DR#%$R';

select row_no, length(data) from dr#testtmpindex0001$r;
select row_no, length(data) from dr#testtmpindex0002$r;
select row_no, length(data) from dr#testtmpindex0003$r;

