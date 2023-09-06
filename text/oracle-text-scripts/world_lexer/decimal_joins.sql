-- Illustrate processing of string "N." where N is a digit

drop table t;
create table t (c varchar2(200));

insert into t values ('3.142857');
insert into t values ('4.');

exec ctx_ddl.drop_preference   ('lx')

-- use WORLD_LEXER -or- BASIC_LEXER with attributes

exec ctx_ddl.create_preference ('lx', 'WORLD_LEXER')

-- exec ctx_ddl.create_preference ('lx', 'BASIC_LEXER')
-- exec ctx_ddl.set_attribute     ('lx', 'NUMJOIN', '.')
-- exec ctx_ddl.set_attribute     ('lx', 'PRINTJOINS', '.')
-- exec ctx_ddl.set_attribute     ('lx', 'PUNCTUATIONS', ' ')

create index ti on t(c) indextype is ctxsys.context parameters ('lexer lx');

select token_text from dr$ti$i;

select * from t where contains(c, '3.%') > 0;
select * from t where contains(c, '3.1%') > 0;

exec Ctx_Query.Explain (index_name => 'TI', text_query=>'3.%', explain_table=>'ctx_explain', sharelevel=>0, explain_id=>'the_id' );

column operation format a30
column object_name format a30
column options format a10

select
lpad ( ' ', 2*(level-1), ' ' ) || lower ( operation )  operation,
       nvl ( options, ' ' ) options,
       object_name
from ctx_explain
where explain_id = 'the_id'
start with id = 1
connect by prior id = parent_id
order by id, position;
