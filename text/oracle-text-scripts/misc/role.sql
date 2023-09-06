connect / as sysdba
set echo on

drop user example cascade;

create user example identified by example;

grant connect,resource,ctxapp to example;

connect example/example

-- works (unnamed PL/SQL block)
begin
  ctx_ddl.create_preference('pref1', 'BASIC_LEXER');
end;
/

-- doesn't work (named PL/SQL block) 
create or replace procedure testproc as
begin
  ctx_ddl.create_preference('pref3', 'BASIC_LEXER');
end;
/
create or replace procedure testproc2 as
begin
  ctx_ddl.create_preference('pref3', 'BASIC_LEXER');
end;
/

