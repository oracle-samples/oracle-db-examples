connect system/oracle

alter user ctxsys account unlock identified by ctxsys;

connect ctxsys/ctxsys

exec ctx_ddl.set_attribute ('basic_lexer', 'NUMGROUP', '.')

connect roger/roger

drop table test;

create table test (text varchar2(2000));
insert into test values ('the.quick.brown.fox 10.2.0.2.1');

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'basic_lexer')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer mylexer');

select token_text from dr$testindex$i;
