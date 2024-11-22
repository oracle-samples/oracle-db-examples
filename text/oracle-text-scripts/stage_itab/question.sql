drop table t;
create table t(c varchar2(2000));
insert into t values ('hello world');
exec ctx_ddl.drop_preference  ('mystor')
exec ctx_ddl.create_preference('mystor', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystor', 'STAGE_ITAB', 'Y')
exec ctx_ddl.set_attribute    ('mystor', 'STAGE_ITAB_MAX_ROWS', '1000')

create index i on t(c) indextype is ctxsys.context parameters('storage mystor sync(on commit)');

begin
  for i in 1..999 loop
    insert into t values ('hello');
  end loop;
  commit;
end;
/
select count(*) from dr$i$g;
select token_text,length(token_info) from dr$i$g;
begin
  for i in 999..1001 loop
    insert into t values ('hello');
    commit;
  end loop;
end;
/
select count(*) from dr$i$g;
select token_text,length(token_info) from dr$i$g;
exec dbms_session.sleep(5)
select count(*) from dr$i$g;
select token_text,length(token_info) from dr$i$g;

