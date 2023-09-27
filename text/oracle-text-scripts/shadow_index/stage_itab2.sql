set echo on

connect sys/oracle as sysdba

drop user testuser cascade;

grant connect,resource,ctxapp,unlimited tablespace to testuser identified by testuser;

connect testuser/testuser

create table docs (id number primary key, text varchar2(2000));

begin
  for i in 1..100 loop
    insert into docs values (i, 'hello'||i);
  end loop;
end;
/

create index docsindex on docs(text) indextype is ctxsys.context
parameters ('sync (on commit)');

insert into docs values (101, 'hello101');
commit;

select token_text from dr$docsindex$g;

--exec ctx_ddl.drop_preference  ('mystorage')
exec ctx_ddl.create_preference('mystorage', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystorage', 'STAGE_ITAB', 'Y')

exec ctx_ddl.recreate_index_online ('docsindex', 'replace storage mystorage')

insert into docs values (102, 'hello102');
commit;

select token_text from dr$docsindex$g;


