set echo on

drop table foo;

create table foo(text varchar2(2000) constraint checkjson check (text is json));

exec ctx_ddl.drop_preference  ('stagestore')
exec ctx_ddl.create_preference('stagestore', 'BASIC_STORAGE')
-- exec ctx_ddl.set_attribute    ('stagestore', 'STAGE_ITAB', 'T')
-- exec ctx_ddl.set_attribute    ('stagestore', 'STAGE_ITAB_MAX_ROWS', '1001')

create search index fooindex on foo(text) for json
parameters(' storage stagestore');

desc dr$fooindex$g

insert into foo values ('hello world');

commit;

select count(*) from dr$fooindex$g;

begin
  for i in 1..1000 loop
    insert into foo values ('{ "foo":"bar'||i||'" }');
    commit;
  end loop;
end;
/

commit;

select count(*) from ctx_user_pending;

select count(*) from dr$fooindex$g;

begin
  sys.dbms_lock.sleep(40); 
end;
/

select count(*) from ctx_user_pending;

select count(*) from dr$fooindex$g;
