drop table testjoin;
create table testjoin (id number primary key, text varchar2(2000));

--insert into testjoin values (1, 'A123B4C');
--insert into testjoin values (2, 'A%B_C');

--insert into testjoin values (1, 'A1B4C');
--insert into testjoin values (2, 'A1B_C');

insert into testjoin values (1, 'A123B4C');
insert into testjoin values (2, 'A%B4C');

exec ctx_ddl.drop_preference('my_lex_pref');
exec ctx_ddl.create_preference('my_lex_pref', 'basic_lexer');
exec ctx_ddl.set_attribute('my_lex_pref', 'printjoins', '%_.');

create index testjoin_index on testjoin (text)
indextype is ctxsys.context
parameters ('lexer my_lex_pref');

set echo on
select text from testjoin WHERE CONTAINS (text, 'A\%B4C') > 0;

