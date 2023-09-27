drop table foo;

create table foo (string varchar2(62 char), text varchar2(2000));

begin
  for i in 1 .. 100 loop
    insert into foo values (i, 'the cat sat on the mat');
  end loop;
end;
/

exec ctx_ddl.drop_preference  ('mywordlist')
exec ctx_ddl.create_preference('mywordlist', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('mywordlist', 'SUBSTRING_INDEX', 'true')

create index fooindex on foo(text) indextype is ctxsys.context
filter by string
parameters ('wordlist mywordlist')
/

select rowid from foo where contains (text, 'cat') > 0
and string = '20'
/



