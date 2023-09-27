set echo on

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

insert into mytable values ('the cat_sat on the_mat');

-- exec ctx_ddl.drop_preference   ('mypref')
exec ctx_ddl.create_preference ('mypref', 'BASIC_LEXER')
exec ctx_ddl.set_attribute     ('mypref', 'PRINTJOINS', '_')

create index myindex on mytable(text) indextype is ctxsys.context;

select token_text from dr$myindex$i;

exec ctx_ddl.recreate_index_online('myindex', 'replace lexer mypref')

select token_text from dr$myindex$i;

 
