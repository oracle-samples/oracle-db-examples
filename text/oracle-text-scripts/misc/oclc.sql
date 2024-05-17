-- dot as a printjoin - this works fine

drop table x
/

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'basic_lexer')
exec ctx_ddl.set_attribute('mylexer', 'printjoins', '.')

create table x (text varchar2(2000));
insert into x values ('The quick brown fox jumps over 1.2 dogs. Next week it''ll be 1.2.a dogs.');

create index xi on x (text) indextype is ctxsys.context
parameters ('lexer mylexer')
/

select token_text from dr$xi$i
/

-- hyphen as a printjoin - really 1.2-a should be indexed as "1", "2-a" but it isn't

drop table x
/

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'basic_lexer')
exec ctx_ddl.set_attribute('mylexer', 'printjoins', '-')

create table x (text varchar2(2000));
insert into x values ('The quick brown fox jumps over 1.2 dogs. Next week it''ll be 1.2-a dogs.');

create index xi on x (text) indextype is ctxsys.context
parameters ('lexer mylexer')
/

select token_text from dr$xi$i
/
