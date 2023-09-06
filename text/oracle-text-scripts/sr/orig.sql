connect demo/demo

drop table tab1 purge;
create table tab1(id number, text varchar2(4000));

insert into tab1 values(1,'a dog makes a wonderful pet');
insert into tab1 values(2,'my favorite is a lab as a pet, but a flobadob is OK');
insert into tab1 values(3,'another canine is a wolf');
insert into tab1 values(4,'This should not hit');
commit;

begin
ctx_ddl.drop_preference('TEST_LEX');
end;
/

begin
ctx_ddl.create_preference('TEST_LEX', 'BASIC_LEXER');
ctx_ddl.set_attribute('TEST_LEX', 'index_themes', 'YES');
end;
/

--
--contents of lab_test.txt
--dogs
-- NT lab
-- NT flobadob

connect ctxsys/ctxsys
exec ctx_thes.drop_thesaurus('test')

-- load thesaurus from a command prompt:

host ctxload -thes -user ctxsys/ctxsys -name test -file lab_test.txt -thescase Y
host ctxkbtc -user ctxsys/ctxsys -name test -verbose

connect roger/roger

drop index tab1_idx;
create index tab1_idx on tab1(text) indextype is ctxsys.context parameters('lexer TEST_LEX');

select id, score(1) from tab1 where contains(text,'about(dogs)',1) > 0;
