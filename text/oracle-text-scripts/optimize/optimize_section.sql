drop table t;
create table t (c varchar2(2000));

insert into t values ('<title>My Document</title><body>Hello World</body>');

exec ctx_ddl.drop_section_group  ('mysg')
exec ctx_ddl.create_section_group('mysg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_field_section   ('mysg', 'title', 'title', false)
exec ctx_ddl.add_field_section   ('mysg', 'body',  'body',  false)

create index i on t(c) indextype is ctxsys.context
parameters ('section group mysg sync(on commit)');

insert into t values ('<title>Another Document</title><body>Hello All</body>');
commit;

-- check fragmentation
column token_text format a30
select token_text, token_type, count(*) from dr$i$i group by token_text, token_type;

-- get the section number for title and use it in call to optimize

variable secnumber number;
begin
  :secnumber := ctx_report.token_type(
                index_name => 'I',
		type_name  => 'FIELD:title');

  ctx_ddl.optimize_index(
                idx_name   => 'I',
		optlevel   => 'TOKEN_TYPE',
		token_type => :secnumber);

end;
/

-- check fragmentation again
select token_text, token_type, count(*) from dr$i$i group by token_text, token_type;
