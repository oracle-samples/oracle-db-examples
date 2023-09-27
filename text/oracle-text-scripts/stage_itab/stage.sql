set echo on

drop table foo;

create table foo(text varchar2(2000));

exec ctx_ddl.drop_preference  ('stagestore')
exec ctx_ddl.create_preference('stagestore', 'BASIC_STORAGE')
-- exec ctx_ddl.set_attribute    ('stagestore', 'STAGE_ITAB', 'T')
--exec ctx_ddl.set_attribute    ('stagestore', 'STAGE_ITAB_MAX_ROWS', '1001')

create index fooindex on foo(text) indextype is ctxsys.context;

desc dr$fooindex$g

insert into foo values ('hello world');

commit;

select count(*) from dr$fooindex$g;

begin
  for i in 1..100000 loop
    insert into foo values ('hello world'||i);
    commit;
  end loop;
end;
/

select count(*) from dr$fooindex$g;

begin
  sys.dbms_lock.sleep(4) 
end;
/

select count(*) from dr$fooindex$g;
