drop table policy;
create table policy (id number, polfile varchar2(2000));

insert into policy values ( 101, 'abc% ksde dk fkakd lightning impulse withstand dkls dkdig skdigls');
insert into policy values ( 201, 'djdiub lightning skdi ksid % skdig aldia');
insert into policy values ( 301, 'skdjd Lightning Impulse Withstand (kV) 11.5/11.5 +/- 12% kdjf skdjld kdjd');
insert into policy values ( 401, 'digke Lightning Impulse Withstand dkfj skdi kskd gkskdig skd sksk skdkd 30% skd');
insert into policy values ( 501, 'skdjflks lightning impulse withstand ksdk dkdkd 10% skdkd');
insert into policy values ( 601, 'dkdj skdjkd lightning impulse withstand ksdk dkdkd % skdjdl');

exec ctx_ddl.drop_preference('polctx_lex')
exec ctx_ddl.create_preference('polctx_lex','basic_lexer')
exec ctx_ddl.set_attribute('polctx_lex','printjoins','_-%')

create index policy_ctx on policy(polfile)
indextype is ctxsys.context
parameters ('lexer polctx_lex');

select token_text from dr$policy_ctx$i where token_text like '%\%' escape '\';

select * from policy where contains (polfile,'%\%') > 0;

