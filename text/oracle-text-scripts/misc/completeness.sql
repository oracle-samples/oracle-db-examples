drop table example;
create table example(text varchar2(255));
insert into example values ('embryogenesis');
insert into example values ('Environmental magnetic fields: influences on early embryogenesis');
exec ctx_ddl.drop_preference('myds')
exec ctx_ddl.create_preference('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute('myds', 'COLUMNS', '''xxstart ''||text||'' xxend''')
create index exampleindex on example(text)
indextype is ctxsys.context
parameters('datastore myds');
select score(0),text from example where contains(text, '(xxstart embryogenesis xxend)*2 OR embryogenesis', 0) > 0;
