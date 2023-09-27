drop table test_user;
create table test_user (first_name varchar2(200));

insert into test_user values ('john smith');
insert into test_user values ('john jones');

exec ctx_ddl.drop_preference   ('cust_lexer')
exec ctx_ddl.create_preference ('cust_lexer', 'BASIC_LEXER')
exec ctx_ddl.set_attribute ('cust_lex1', 'base_letter', 'YES')

exec ctx_ddl.drop_preference   ('cust_wl')
exec ctx_ddl.create_preference ('cust_wl', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute     ('cust_wl', 'SUBSTRING_INDEX', 'true')

CREATE INDEX TEST_USER_IDX ON TEST_USER 
(FIRST_NAME) 
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS('LEXER cust_lexer WORDLIST cust_wl sync (on commit)'); 

select token_text from dr$test_user_idx$i;

insert into test_user values ('john brown');
commit;

select token_text from dr$test_user_idx$i;

exec ctx_ddl.optimize_index('test_user_idx', 'FULL')

select token_text from dr$test_user_idx$i;
