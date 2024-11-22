drop table jtest_tab;

create table jtest_tab (test_col varchar2(60));
insert all into jtest_tab values ('STOP MOLD VINYL/VINYL MO 8')
  into jtest_tab values ('STOP MOLD VINYL WITH END FLAP MO 10')
  select * from dual;

show errors

create index jtest_tab_idx on jtest_tab (test_col) INDEXTYPE IS CTXSYS.CONTEXT;

exec ctx_thes.drop_thesaurus   ('jtest_thes')
exec ctx_thes.create_thesaurus ('jtest_thes')

exec ctx_thes.create_relation ('jtest_thes','MO', 'syn', 'MEDIUM OAK');

select * from jtest_tab where contains (test_col, 'MO') > 0;

select * from jtest_tab where contains (test_col, 'SYN(MEDIUM OAK, JTEST_THES)') > 0;


