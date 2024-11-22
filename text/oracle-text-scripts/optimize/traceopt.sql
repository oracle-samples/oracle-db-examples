set echo on

drop table foo;

create table foo (text varchar2(2000));

create index fooindex on foo(text) indextype is ctxsys.context;

begin
  for i in 1 .. 1000 loop
    insert into foo values ('hello world the quick brown fox');  
    commit;
    ctx_ddl.sync_index('fooindex');
  end loop;
end;
/

begin
  ctx_output.start_log('optimize.log');
  ctx_output.add_event(ctx_output.EVENT_OPT_PRINT_TOKEN);

  ctx_ddl.optimize_index('fooindex', 'FULL');

  ctx_output.end_log;
end;
/
