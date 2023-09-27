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

exec ctx_ddl.create_shadow_index('docsindex', 'replace lexer ctxsys.default_lexer NOPOPULATE');

-- what indexes currently exist in my schema?

column idx_id new_value idxid

select idx_id from ctx_user_indexes where idx_name = 'DOCSINDEX'; 


-- populate pending
exec ctx_ddl.populate_pending('RIO$'||&idxid)

-- how many rows to sync?
select pnd_index_name, count(*) "Rows to sync" from ctx_user_pending group by pnd_index_name;

-- sync in parallel 
exec ctx_ddl.sync_index(idx_name =>'RIO$'||&idxid, parallel_degree => 4)

-- swap in the shadow index 
exec ctx_ddl.exchange_shadow_index('docsindex');

-- do some queries
select * from docs where contains(text, 'hello1') > 0;
select * from docs where contains(text, 'hello50') > 0;
select * from docs where contains(text, 'hello100') > 0;

