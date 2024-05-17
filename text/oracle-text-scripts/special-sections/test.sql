drop table foo;

create table testtable (text varchar2(2000));

insert into testtable values ('the quick brown fox. Jumps over the lazy dog');

exec ctx_ddl.drop_section_group('mysg')
exec ctx_ddl.create_section_group('mysg', 'BASIC_SECTION_GROUP')
-- exec ctx_ddl.add_zone_section('mysg', 'SENTENCE')
exec ctx_ddl.add_special_section('mysg', 'SENTENCE')

create index testindex on testtable(text) indextype is ctxsys.context
parameters('section group mysg');

select * from testtable where contains(text, 'brown within sentence') > 0;


begin
  ctx_ddl.create_section_group('"RELDINDXRELTEXT_SGP"','BASIC_SECTION_GROUP');
  ctx_ddl.add_zone_section('"RELDINDXRELTEXT_SGP"','SENTENCE', 'SENTENCE');
  ctx_ddl.add_zone_section('"RELDINDXRELTEXT_SGP"','PARAGRAPH', 'PARAGRAPH');
end;
/
