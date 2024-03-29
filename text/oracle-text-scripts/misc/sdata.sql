set echo on

drop table foo;

create table foo (text varchar2(2000), anum number);

insert into foo values ('<category>car truck motorcycle</category>', 111);

exec ctx_ddl.drop_section_group('mysec')
exec ctx_ddl.create_section_group('mysec', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_sdata_section('mysec', 'category', 'category')

create index fooindex on foo (text) indextype is ctxsys.context
filter by anum;

select table_name from user_tables where table_name like 'DR$FOOINDEX$%';

select sdata_id, sdata_last from DR$FOOINDEX$S;

insert into foo values ('goodbye world', 222);

select sdata_id, sdata_last from DR$FOOINDEX$S;

select count(*) from ctxsys.drv$sdata_update;

select * from foo where contains( text, 'sdata(category like ''%truck%'')' ) > 0;

-- commit;

-- exec ctx_ddl.sync_index('fooindex');

-- select sdata_id, sdata_last from DR$FOOINDEX$S;
