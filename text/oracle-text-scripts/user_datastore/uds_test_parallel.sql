create or replace procedure udsproc(r rowid, o in out nocopy clob) is
begin
  select c into o from t where rowid = r;
end;
/
show errors

drop table t;

create table t(c varchar2(200));
insert into t values ('hello world');
insert into t values ('the quick brown fox');

exec ctx_ddl.drop_preference  ('myuds')
exec ctx_ddl.create_preference('myuds', 'USER_DATASTORE')
exec ctx_ddl.set_attribute    ('myuds', 'PROCEDURE', 'udsproc')

create index t on t(c) indextype is ctxsys.context parameters ('datastore myuds');

select * from t where contains (c, 'world') > 0;

create or replace function udstest(r rowid) return varchar2 is
  clb clob;
begin
  dbms_lob.createtemporary(clb, true);
  udsproc(r, clb);
  return (substr(clb, 1, 200));
end;
/
show err

alter table t parallel 4;

select /*+ PARALLEL(t, 4) */ udstest(rowid)
from t;
