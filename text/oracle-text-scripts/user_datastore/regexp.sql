create table foo(text clob);

insert into foo values (
   'the quick brown fox'||chr(10)||
   '## want this line'||chr(10)||
   'foo bar'||chr(10)||
   '### want this line too'||chr(10)||
   'last line');
