

create index jtest_tab_idx on jtest_tab (test_col) INDEXTYPE IS CTXSYS.CONTEXT;

exec ctx_thes.drop_thesaurus   ('jtest_thes')
exec ctx_thes.create_thesaurus ('jtest_thes')

exec ctx_thes.create_relation ('jtest_thes','MO', 'syn', 'MEDIUM OAK');

select * from jtest_tab where contains (test_col, 'MO') > 0;

select * from jtest_tab  where contains (test_col, 'SYN(MO,jtest_thes)') > 0;

select * from jtest_tab   where contains (test_col, 'SYN(MEDIUM,jtest_thes) and SYN(OAK,jtest_thes)') > 0;

insert into jtest_tab values ('STOP MOLD VINYL WH 12');

drop index jtest_tab_idx;

create index jtest_tab_idx on jtest_tab (test_col) INDEXTYPE IS CTXSYS.CONTEXT;

exec ctx_thes.create_relation ('jtest_thes','WH','syn','WHITE');

select * from jtest_tab where contains (test_col, 'SYN(WHITE,jtest_thes)')>0;

