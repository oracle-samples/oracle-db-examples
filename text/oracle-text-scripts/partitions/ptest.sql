drop table ptest;

create table ptest (pk number primary key, text varchar2(2000));

insert into ptest values (1, 'hello world');
insert into ptest values (2, 'goodbye cruel world');
insert into ptest values (3, 'the quick brown fox jumps over the lazy dog');
insert into ptest values (4, 'now is the time for all good men');


exec ctx_output.start_log ('ptest1');

create index ptest_index on ptest(text) indextype is ctxsys.context
parallel 8;

exec ctx_output.end_log;

exec ctx_output.start_log ('ptest2');

insert into ptest values (5, 'and did those feet in ancient times');
insert into ptest values (6, 'walk upon england''s mountains green');
insert into ptest values (7, 'and was the holy lamb of god');
insert into ptest values (8, 'on england''s pleasant pastures seen');

exec ctx_ddl.sync_index	(idx_name=>'ptest_index', parallel_degree=>4);

exec ctx_output.end_log;

