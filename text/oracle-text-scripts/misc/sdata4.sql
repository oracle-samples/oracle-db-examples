drop table foobar;
create table foobar (txt varchar2(2000), settlement_id number);

insert into foobar values ('hello', 21);

exec ctx_ddl.drop_section_group('msg')
exec ctx_ddl.create_section_group('msg', 'basic_section_group')
exec ctx_ddl.add_sdata_section('msg', 'SETID', 'SETID', 'number')

exec ctx_ddl.drop_preference('mds')
exec ctx_ddl.create_preference('mds', 'multi_column_datastore')
exec ctx_ddl.set_attribute('mds', 'columns', 'txt, ''<SETID>''||settlement_id||''</SET_ID>''')

create index foobarind on foobar(txt) indextype is ctxsys.context
parameters ('section group msg datastore mds');

select * from foobar where contains (txt, 'hello and SDATA(SETID=21)') > 0;
