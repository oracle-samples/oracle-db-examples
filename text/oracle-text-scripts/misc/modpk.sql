drop table modpk_test;

create table modpk_test 
(firstcol number, secondcol number, thirdcol varchar2(200));

alter table modpk_test add constraint modpk_pk primary key (firstcol);

insert into modpk_test values (1, 2, 'hello world');

create index modpk_index on modpk_test (thirdcol) indextype is ctxsys.context;

create global temporary table ctx_mutab
  (
    query_id number constraint ctx_mutab_pk primary key,
    document clob
  ) on commit preserve rows;

exec ctx_doc.markup ('modpk_index', ctx_doc.pkencode(1), 'hello', 'ctx_mutab');

select document from ctx_mutab;

alter table modpk_test drop constraint modpk_pk;
alter table modpk_test add constraint modpk_pk primary key (firstcol, secondcol);

exec ctx_doc.markup ('modpk_index', ctx_doc.pkencode(1,2), 'hello', 'ctx_mutab');

select document from ctx_mutab;

exec ctx_doc.markup ('modpk_index', '1', 'hello', 'ctx_mutab');
