set echo on

drop table testtmp;
create table testtmp (id number, text varchar2(80));

begin
  for i in 1..70002 loop
    insert into testtmp values (i, 'hello'||i);
  end loop;
end;
/

exec ctx_ddl.drop_preference  ('mystorage')
exec ctx_ddl.create_preference('mystorage', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystorage', 'SMALL_R_ROW', 'T')

create index testtmpindex on testtmp(text) 
indextype is ctxsys.context
parameters ('storage mystorage');

select row_no, length(data) from dr$testtmpindex$r;

drop table testtmp2;
create table testtmp2 (id number, text varchar2(80));

begin
  for i in 1..70002 loop
    insert into testtmp2 values (i, 'hello'||i);
  end loop;
end;
/

exec ctx_ddl.drop_preference  ('mystorage')
exec ctx_ddl.create_preference('mystorage', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystorage', 'SMALL_R_ROW', 'F')

create index testtmp2index on testtmp2(text) 
indextype is ctxsys.context
parameters ('storage mystorage');

select row_no, length(data) from dr$testtmp2index$r;

