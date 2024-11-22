drop table t;
create table t (text varchar2(2000));

insert into t values ('i am working today');
insert into t values ('i worked yesterday too');
insert into t values ('i will be working, working, working tomorrow');

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'basic_lexer')
exec ctx_ddl.set_attribute('mylexer', 'index_stems', 'ENGLISH')

create index ti on t(text) indextype is ctxsys.context
parameters ('lexer mylexer');

column token_text format a30
select token_text, token_type, token_count from dr$ti$i;
