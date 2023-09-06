set feedback off

drop table avtest;
exec ctx_ddl.drop_preference('avtestlex')

create table avtest (text varchar2(4000));

insert into avtest values ('cat');
insert into avtest values ('cat dog');
insert into avtest values ('cat dog rabbit');
insert into avtest values ('cat dog rabbit fox');
insert into avtest values ('cat dog rabbit fox fish');
insert into avtest values ('dog cat');
insert into avtest values ('dog rabbit fox cat');
insert into avtest values ('dog rabbit fox fish cat');
insert into avtest values ('the cat and the dog and the rabbit but not the fish');
insert into avtest values ('the cat nt dog bt');
insert into avtest values ('the cat nt dog bt rabbit');
insert into avtest values ('the cat-dog bites the fox-fish');

exec ctx_ddl.create_preference('avtestlex', 'basic_lexer')
--exec ctx_ddl.set_attribute('avtestlex', 'printjoins', '.]')
--exec ctx_ddl.set_attribute('avtestlex', 'skipjoins', '[-^')

exec ctx_ddl.set_attribute('avtestlex', 'printjoins', '.]-')
exec ctx_ddl.set_attribute('avtestlex', 'skipjoins', '[')

create index avtestindex on avtest(text) indextype is ctxsys.context
parameters ('lexer avtestlex');

set feedback on