set echo on
spool stephane.log

drop user user2 cascade;
create user user2 identified by user2 default tablespace users temporary tablespace temp quota unlimited on users;
grant connect,resource to user2;
BEGIN
        CTX_DDL.CREATE_PREFERENCE ('USER2.NO_ACCENT_LEXER', 'BASIC_LEXER');
        CTX_DDL.SET_ATTRIBUTE ('USER2.NO_ACCENT_LEXER', 'base_letter', 'YES');
END;
/

connect user2/user2
create table TEST(a number,b varchar2(100));
insert into TEST(a,b) values (1,'Stephane');
insert into TEST(a,b) values (2,'Stéphane');
commit;

column B format a40
select * from test;

CREATE INDEX USER2.IT_TEST on USER2.TEST(b) INDEXTYPE IS CTXSYS.CONTEXT PARAMETERS('STOPLIST CTXSYS.EMPTY_STOPLIST SYNC(ON COMMIT) LEXER NO_ACCENT_LEXER TRANSACTIONAL');

select * from user2.TEST where contains(b,'STEPHANE')>0;
