drop table t1;
create table t1 (text varchar2(2000));

exec ctx_ddl.drop_preference('my_world_lexer')
exec ctx_ddl.create_preference('my_world_lexer', 'world_lexer')

insert into t1 values ('AB1.-'||chr(13)||'2CD');
insert into t1 values ('XY1-'||chr(13)||'.2CD');

create index t1_index on t1(text) indextype is ctxsys.context
parameters('lexer my_world_lexer');

select token_text from dr$t1_index$i;
