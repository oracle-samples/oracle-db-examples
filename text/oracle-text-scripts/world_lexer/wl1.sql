exec ctx_ddl.drop_preference  ('wl')
exec ctx_ddl.create_preference('wl', 'WORLD_LEXER')

drop table t;
create table t (c varchar2(200));
insert into t values ('12');
insert into t values ('13.');
insert into t values ('14.1');

create index ti on t(c) indextype is ctxsys.context parameters ('lexer wl');
-- create index ti on t(c) indextype is ctxsys.context;

select token_text from dr$ti$i;

select * from t where contains(c, '13.') > 0;
select * from t where contains(c, '13.%') > 0;
select * from t where contains(c, '13') > 0;
select * from t where contains(c, '14\.%') > 0;

exec Ctx_Query.Explain (index_name => 'TI', text_query=>'14\.%', explain_table=>'ctx_explain', sharelevel=>0, explain_id=>'the_id' );

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
