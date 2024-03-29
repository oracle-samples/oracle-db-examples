exec ctx_ddl.drop_policy (policy_name => 'foopolicy')
exec ctx_ddl.drop_preference   ('myuds')
drop table foo;

create table foo (title varchar2(80), fileloc varchar2(200));

insert into foo values ('A doc called hello', '/eddie/e/hello.doc');

exec ctx_ddl.create_policy (policy_name => 'foopolicy', filter => 'CTXSYS.INSO_FILTER')

create or replace procedure fooproc (
    rid  in              rowid,
    tlob in out NOCOPY   clob ) is

  v_title varchar2(4000);
  v_fileloc clob;
  v_clob clob;

begin
  select title, fileloc into v_title, v_clob
  from foo where rowid = rid;

  ctx_doc.policy_filter(
    policy_name => 'foopolicy',
    document    => v_clob,
    restab      => tlob,
    plaintext   => TRUE);

end;
/

exec ctx_ddl.create_preference ('myuds', 'USER_DATASTORE')
exec ctx_ddl.set_attribute     ('myuds', 'PROCEDURE', 'fooproc')

create index fooindex on foo (fileloc) indextype is ctxsys.context
parameters ('datastore myuds')
/

select token_text from dr$fooindex$i
/
