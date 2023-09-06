set echo on
drop index tab1_idx;
create index tab1_idx on tab1(text) indextype is ctxsys.context parameters('lexer TEST_LEX');

column THES format a60
column ABOUT format a60
select text "THES", score(1) from tab1 where contains(text, 'rt(dog, test)', 1) > 0;

select text "ABOUT", score(1) from tab1 where contains(text,'about(dogs)',1) > 0;
select text "ABOUT", score(1) from tab1 where contains(text,'about(pets)',1) > 0;
