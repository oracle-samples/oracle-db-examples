drop table items;
create table items (text varchar2(2000));

insert into items values ('GREENHECK FAN');
insert into items values ('CED GREENTECH');
insert into items values ('GREEN HECK GROUP');
insert into items values ('GREENTECH RENEWABLES');

exec ctx_ddl.drop_preference  ('myds')
exec ctx_ddl.create_preference('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('myds', 'COLUMNS', '''<nd>''||text||''</nd>''')

exec ctx_ddl.drop_section_group  ('mysg')
exec ctx_ddl.create_section_group('mysg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_ndata_section   ('mysg', 'nd', 'nd')

create index itemsindex on items(text) 
indextype is ctxsys.context
parameters ('datastore myds section group mysg');

select * from items where contains(text, 'ndata(nd, greenheck)') > 0;

