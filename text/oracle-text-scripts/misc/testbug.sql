create table test_sus (id number primary key, txt clob);

create index ctx_test_sus
on test_sus(txt) indextype is ctxsys.context
parameters ('nopopulate section group ctxsys.auto_section_group');

insert into test_sus values(1,
'<bbb b<ccccccccccccccccccccccccccccccccc<ddddddddddddddddddddddddd <e>'
);

begin
  ctx_ddl.sync_index('CTX_TEST_SUS'); 
  end;
/
