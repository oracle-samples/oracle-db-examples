-- testcase illustrating that 'replace metadata fast_dml' will break EXCHANGE_SHADOW_INDEX

set echo on
set serveroutput on

connect / as sysdba

drop user testuser cascade;

grant connect,resource,ctxapp,unlimited tablespace to testuser identified by testuser;

connect testuser/testuser

create table docs (id number primary key, text varchar2(2000));

insert into docs values (1, 'hello world');

create index docsindex on docs(text) indextype is ctxsys.context parameters('fast_query');

desc dr$docsindex$k

-- Go to fast_query and back to fast_dml - see NOT NULL constraint is added

alter index docsindex rebuild parameters ('replace metadata fast_dml');

alter index docsindex rebuild parameters ('replace metadata fast_query');

alter index docsindex rebuild parameters ('replace metadata fast_dml');

-- this will be different
desc dr$docsindex$k

exec ctx_ddl.create_shadow_index('docsindex');

-- get the index ID into variable idxid

column idx_id new_value idxid
select to_char(idx_id) as idx_id from ctx_user_indexes where idx_name = 'DOCSINDEX'; 

-- compare main and shadow $K tables

describe dr$docsindex$k

describe dr$rio$&idxid$k

-- exchange shadow index will fail

exec ctx_ddl.exchange_shadow_index('DOCSINDEX')

-- if we drop the constraint it will succeed

declare 
   cons_name varchar2(32);
begin
   select constraint_name into cons_name 
     from user_constraints 
     where table_name = 'DR$DOCSINDEX$K';
   dbms_output.put_line('Dropping constraint '||cons_name||'...');
   execute immediate ('alter table dr$docsindex$k drop constraint '||cons_name);
end;
/


-- exchange shadow index will now work

exec ctx_ddl.exchange_shadow_index('DOCSINDEX')
