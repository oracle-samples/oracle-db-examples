connect sys/oracle@den00btl as sysdba
drop user cntest cascade;
create user cntest identified by cntest default tablespace users temporary tablespace temp quota unlimited on users;
grant connect,resource,ctxapp to cntest;

connect cntest/cntest@den00btl

create table t (text varchar2(20));
insert into t values ('the quick brown fox');
insert into t values ('???');

exec ctx_ddl.create_preference('cnlex', 'WORLD_LEXER')

create index ti on t(text) indextype is ctxsys.context
parameters ('lexer cnlex');

column token_text format a20
column dmp format a80
select text, dump(text,16) as dmp from t;
select token_text, dump(token_text,16) as dmp from dr$ti$i;

