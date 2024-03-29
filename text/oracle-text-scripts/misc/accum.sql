drop table foo;

create table foo(bar varchar2(60));

insert into foo values ('man dog');
insert into foo values ('man dog cat');
insert into foo values ('man dog cat stick');
insert into foo values ('man dog cat stick tree');
insert into foo values ('man dog cat stick tree fetch');

create index foobar on foo(bar) indextype is ctxsys.context;

select score(0), bar from foo where contains (bar, 'man , dog , cat , stick , tree , fetch', 0) > 0;

select score(0), bar from foo where contains (bar, 'man , dog , cat , stick , tree , fetch', 0) > 32;

