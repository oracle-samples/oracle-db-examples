drop table t;
create table t (id int primary key, doc varchar2(2000));

-- 1 to 5 occurrences of the word "oracle"
insert into t values (1, 'oracle');
insert into t values (2, 'oracle oracle');
insert into t values (3, 'oracle oracle oracle');
insert into t values (4, 'oracle oracle oracle oracle');
insert into t values (5, 'oracle oracle oracle oracle oracle');

-- 110 occurrences of the word "oracle"
insert into t values (6, 'oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle oracle');

create index t_index on t(doc) indextype is ctxsys.context;

select id, score(1) as occurrence_count from t where contains( doc, '
<query>
  <textquery>
    oracle
  </textquery>
  <score algorithm="count" />
</query>
', 1) > 0;

set serverout on

begin
  ctx_ddl.create_policy (
     policy_name => 'occurrence_policy'
  );
end;
/

create or replace function occurrence_count
   (document varchar2,
    search_term varchar2
   )
return number is 
  highlight_tab ctx_doc.highlight_tab;
begin
  for c in ( select id, doc from t ) loop
    ctx_doc.policy_highlight( 'T_INDEX', document, search_term, highlight_tab);
    return highlight_tab.count;
  end loop;
end;
/

select id, occurrence_count( doc, 'oracle') from T;
