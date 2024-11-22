-- simple test script using AUTO_LEXER

set echo on

connect sys/oracle as sysdba

drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table table1 (text varchar2(2000));

insert into table1 values ('the quick brown fox jumps over the lazy dog');

exec ctx_ddl.create_preference('autolex', 'auto_lexer')

create index table1_index on table1(text) indextype is ctxsys.context
parameters ('lexer autolex');


-- Look to see what tokens were indexed
select token_text from dr$table1_index$i;

-- Run some queries

-- simple word
select text from table1 where contains (text, 'dog')> 0;

-- phrase 
select text from table1 where contains (text, 'lazy dog')> 0;

-- AND search
select text from table1 where contains (text, 'brown AND dog') > 0;

