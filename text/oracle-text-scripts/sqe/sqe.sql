set echo on

connect roger/roger

drop table foo;

create table foo (text varchar2(2000));

insert into foo values ('cat dog rabbit');

exec ctx_query.remove_sqe('sqe_1')

exec ctx_query.store_sqe('sqe_1', 'dog')

create index fooind on foo(text) indextype is ctxsys.context;

grant select on foo to testuser;

connect testuser/testuser

-- this will fail with DRG-10825: stored query does not exist: sqe_1
select * from roger.foo where contains (text, 'cat and sqe(sqe_1)') > 0;

-- this will work
select * from roger.foo where contains (text, 'cat and sqe(roger.sqe_1)') > 0;

-- confirming that it works in progressive relaxation:
select * from roger.foo where contains (text, '
<query>
  <textquery>
    <progression>
      <seq>elephant</seq>
      <seq>cat AND sqe(roger.sqe_1)</seq>
    </progression>
  </textquery>
</query>
') > 0;
