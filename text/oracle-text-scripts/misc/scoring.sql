drop table foo;

create table foo (id number, text varchar2(4000));

insert into foo values (1, 'the cat sat on the mat');
insert into foo values (2, 'the cat sat on the cat');
insert into foo values (3, 'cat cat cat dog');
insert into foo values (4, 'cat cat cat dog dog');

create index fooindex on foo(text)
indextype is ctxsys.context;

column text format a50

select score(1), text from foo where contains (text, 'cat', 1) > 0; 
select score(1), text from foo where contains (text, 'dog', 1) > 0;
select score(1), text from foo where contains (text, 'cat AND dog', 1) > 0; 
select score(1), text from foo where contains (text, 'cat OR dog', 1) > 0; 
select score(1), text from foo where contains (text, 'cat ACCUM dog', 1) > 0; 
