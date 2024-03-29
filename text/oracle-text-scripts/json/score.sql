drop table t;
-- create table t (c json);
create table t (c varchar2(2000) check (c is json));
insert into t values ('{ "a": "dog", "b": "dog dog" }');
insert into t values ('{ "a": "dog dog", "b": "dog" }');
create search index i on t(c) for json;
select score(1), score(2), c from t
  where json_textcontains(c, '$.a', 'dog', 1)
  or    json_textcontains(c, '$.b', 'dog', 2);
