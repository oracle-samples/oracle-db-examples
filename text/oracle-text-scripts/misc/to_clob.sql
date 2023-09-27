drop table foo;
create table foo(bar varchar2(2000));

insert into foo values ('hello world')

exec ctx_ddl.drop_section_group  ('mysg')
exec ctx_ddl.create_section_group('mysg', 'BASIC_SECTION_GROUP')

exec ctx_ddl.add_field_section   ('mysg', 'name'       , 'name')
exec ctx_ddl.add_field_section   ('mysg', 'category'   , 'category')
exec ctx_ddl.add_field_section   ('mysg', 'source'     , 'source')
exec ctx_ddl.add_field_section   ('mysg', 'tags'       , 'tags')
exec ctx_ddl.add_field_section   ('mysg', 'description', 'description')

create index fooindex on foo(bar) indextype is ctxsys.context
parameters ('section group mysg')
/

SELECT * FROM (SELECT score(1)
FROM foo where
CONTAINS(bar,
TO_CLOB(
'DEFINEMERGE((((DEFINESCORE(construction%,OCCURRENCE)  WITHIN name)*8),
 ((DEFINESCORE(construction%,OCCURRENCE)  WITHIN category)*4),
 ((DEFINESCORE(construction%,OCCURRENCE)  WITHIN source)*2),
 ((DEFINESCORE(construction%,OCCURRENCE)  WITHIN tags)*3),
 ((DEFINESCORE(construction%,OCCURRENCE)  WITHIN description))), OR, ADD)')
,1) > 0
order by score(1) desc) results2 WHERE rownum <= 50 ORDER BY rownum;
