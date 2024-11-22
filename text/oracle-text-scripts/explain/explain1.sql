drop table ctx_explain;
create table ctx_explain (
    explain_id   varchar2(30),
    id           number,
    parent_id    number,
    operation    varchar2(30),
    options      varchar2(30),
    object_name  varchar2(64),
    position     number,
    cardinality  number
  );

exec Ctx_Query.Explain (index_name => 'TESTINDEX', text_query=>'%123%', explain_table=>'ctx_explain', sharelevel=>0, explain_id=>'the_id' );

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
