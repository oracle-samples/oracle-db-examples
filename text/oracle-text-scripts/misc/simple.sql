connect sys/manager1 as sysdba
create user mytestuser identified by mytestuser default tablespace users temporary tablespace temp;
grant connect,resource,ctxapp to mytestuser;

connect mytestuser/mytestuser

create table test1 (id number primary key, text varchar2(200));

insert into test1 values (1, 'the quick brown fox jumps over the lazy dog');

exec ctx_ddl.create_preference('my_lexer', 'basic_lexer');

create index test1_index on test1 (text)
indextype is ctxsys.context
parameters ('lexer my_lexer');

select * from test1 where contains (text, 'fox') > 0;


