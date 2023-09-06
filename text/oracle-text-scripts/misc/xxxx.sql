
drop table mystuff;

create table mystuff (url varchar2(10), referrer varchar2(30), urlfield varchar2(30));

insert into mystuff values ('url1', 'InitiateInt', 'foo');
insert into mystuff values ('url2', 'InitiateInt', 'password');

exec ctx_ddl.drop_preference('my_multi')
exec ctx_ddl.drop_preference('my_lexer')
exec ctx_ddl.drop_preference('my_wordlist')
exec ctx_ddl.drop_section_group('my_sg')

BEGIN
  ctx_ddl.create_preference('my_multi', 'MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('my_multi', 'columns', 'referrer, urlfield');

  CTX_DDL.CREATE_PREFERENCE ('my_lexer', 'BASIC_LEXER');
  CTX_DDL.SET_ATTRIBUTE ('my_lexer', 'PRINTJOINS', '%');

  CTX_DDL.CREATE_PREFERENCE ('my_wordlist', 'BASIC_WORDLIST');
  CTX_DDL.SET_ATTRIBUTE ('my_wordlist', 'WILDCARD_MAXTERMS', '15000');

  CTX_DDL.CREATE_SECTION_GROUP('my_sg', 'basic_section_group');
  CTX_DDL.ADD_FIELD_SECTION('my_sg', 'REFERRER', 'REFERRER');
  CTX_DDL.ADD_FIELD_SECTION('my_sg', 'URLFIELD', 'URLFIELD');
END;
/

CREATE INDEX my_idx on mystuff (url) indextype is ctxsys.context
PARAMETERS
('LEXER         my_lexer
  WORDLIST      my_wordlist
  datastore     my_multi
  section group my_sg
')
/

select * from mystuff
where contains(url , '( InitiateInt within referrer ) not ( password within urlfield )', 0 ) > 0;
;
