set echo on
set timing on

connect system/oracle
drop user shadow cascade;
drop tablespace shadow including datafiles and contents;

create user shadow identified by shadow;
create tablespace shadow datafile 'shadow.dbf' size 100M autoextend on;

grant connect,resource,ctxapp,unlimited tablespace,alter session to shadow;

alter user shadow default tablespace shadow;

connect shadow/shadow

-- drop table mytable;

create table mytable (text varchar2(2000));

begin
  for i in 1..1000000 loop
    insert into mytable values ('the cat_sat on the_mat');
  end loop;
end;
/

-- exec ctx_ddl.drop_preference   ('mypref')

create index myindex on mytable(text) indextype is ctxsys.context;

select token_text,count(*) from dr$myindex$i group by token_text;

exec ctx_ddl.create_preference ('mypref', 'BASIC_LEXER')
exec ctx_ddl.set_attribute     ('mypref', 'PRINTJOINS', '_')

exec ctx_ddl.create_shadow_index('myindex', 'replace lexer mypref')

exec ctx_ddl.exchange_shadow_index('myindex')

select token_text,count(*) from dr$myindex$i group by token_text;

 
