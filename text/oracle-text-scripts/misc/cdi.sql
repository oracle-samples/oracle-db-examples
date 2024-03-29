drop table foo;

create table foo (numeric number, text varchar2(2000));

begin
  for i in 1 .. 100000 loop
    insert into foo values (i, 'the cat sat on the mat');
  end loop;
end;
/

create index fooindex on foo(text) indextype is ctxsys.context
filter by numeric
/

alter system flush buffer_cache;
alter system flush shared_pool;

EXEC dbms_workload_repository.create_snapshot;

begin
  for i in 1 .. 100000 loop
    delete from foo where numeric = i;
  end loop;
end;
/
commit;

EXEC dbms_workload_repository.create_snapshot;

@?/rdbms/admin/awrrpt.sql
