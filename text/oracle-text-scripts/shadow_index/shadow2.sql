set echo on

connect / as sysdba

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

create index docsindex on docs(text) indextype is ctxsys.context;

desc dr$docsindex$k

alter index docsindex rebuild parameters ('replace metadata fast_query');

alter index docsindex rebuild parameters ('replace metadata fast_dml');

desc dr$docsindex$k

exec ctx_ddl.create_shadow_index('docsindex');

-- what indexes currently exist in my schema?

column idx_id new_value idxid

select idx_id from ctx_user_indexes where idx_name = 'DOCSINDEX'; 

-- compare shadow and main $K tables

describe dr$docsindex$k

prompt &idxid

