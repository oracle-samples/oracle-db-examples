exec ctx_ddl.drop_preference('mylex')
exec ctx_ddl.create_preference('mylex', 'basic_lexer')

exec ctx_ddl.set_attribute('mylex','PRINTJOINS','-/():*"`<>=#~@$[]{}'||chr(38)||chr(180)||chr(167)||chr(178)||chr(39)); 

drop table xx;
create table xx (txt varchar2(200));
insert into xx values ('hello'||chr(180)||'world');

select dump(prv_value)
from CTX_USER_PREFERENCE_VALUES 
where prv_attribute ='PRINTJOINS' 
and prv_preference='MYLEX' ; 

create index xxi on xx(txt) indextype is ctxsys.context
parameters ('lexer mylex');

select token_text, dump(token_text) from dr$xxi$i;

