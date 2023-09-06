set echo on

drop table tab1 purge;
create table tab1(id number primary key, text varchar2(4000));

insert into tab1 values(1,'a dog makes a wonderful pet');
insert into tab1 values(2,'my favorite is a lab as a pet');
insert into tab1 values(3,'another canini is a wolf');
insert into tab1 values(4,'This should not hit');
insert into tab1 values(5,'a lab is nice but a phudpook is better');
insert into tab1 values(6,'my favorite is a phudpook as a pet');
commit;

begin
  ctx_ddl.drop_preference('TEST_LEX');
end;
/

begin
  ctx_ddl.create_preference('TEST_LEX', 'BASIC_LEXER');
  ctx_ddl.set_attribute('TEST_LEX', 'index_themes', 'YES');
  ctx_ddl.set_attribute('TEST_LEX', 'PROVE_THEMES', 'NO');
end;
/

--
--
--
--contents of lab_test.txt
--dog
-- USE dog
-- SYN lab
-- SYN Lab
--dog
-- SYN canine
--
--
--
-- load thesaurus from a command prompt:
--
connect ctxsys/ctxsys
exec ctx_thes.drop_thesaurus('test')

connect roger/roger

host ctxload -thes -user ctxsys/ctxsys -name test -file lab_test.txt -thescase Y

host ctxkbtc -user ctxsys/ctxsys -revert
host ctxkbtc -user ctxsys/ctxsys -name test -verbose

quit

