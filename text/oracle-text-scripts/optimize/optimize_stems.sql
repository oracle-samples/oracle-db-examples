drop table t;
create table t (c varchar2(2000));

insert into t values ('<title>The dog ran away');

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('mylexer', 'INDEX_STEMS', 'ENGLISH')

create index i on t(c) indextype is ctxsys.context
parameters ('lexer mylexer sync(on commit)');

insert into t values ('My dog is running away too');
commit;

-- check fragmentation
column token_text format a30
select token_text, token_type, count(*) from dr$i$i group by token_text, token_type;

-- get the section number for title and use it in call to optimize

variable secnumber number;
begin
  :secnumber := ctx_report.token_type(
                index_name => 'I',
		type_name  => 'STEM');

  ctx_ddl.optimize_index(
                idx_name   => 'I',
		optlevel   => 'TOKEN_TYPE',
		token_type => :secnumber);

end;
/

-- check fragmentation again
select token_text, token_type, count(*) from dr$i$i group by token_text, token_type;
