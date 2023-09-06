create table t (text varchar2(2000));

insert into t values ('<a>the quick brown fox</a><b>jumps over the lazy dog</b>');

exec ctx_ddl.create_section_group('tsg', 'basic_section_group')
exec ctx_ddl.add_field_section('tsg', 'a', 'a', visible=>false)
exec ctx_ddl.add_field_section('tsg', 'b', 'b', visible=>false)

create index ti on t(text) indextype is ctxsys.context
parameters ('section group tsg');

alter session set sql_trace=true;

select text from t where contains (text, 'quick within a') > 0;

alter session set sql_trace=false;

