drop table foo;
create table foo (text varchar2(30));

insert into foo values ('fred');
insert into foo values ('maria');
insert into foo values ('fred maria');
insert into foo values ('fred fred');
insert into foo values ('maria maria');
insert into foo values ('fred fred fred');
insert into foo values ('fred fred fred fred fred');

create index fooind on foo(text) indextype is ctxsys.context;

select score(1), text from foo where 
   contains (text, 'fred OR maria', 1) >0 order by score(1) desc;
select score(1), text from foo where 
   contains (text, 'fred EQUIV maria', 1) >0 order by score(1) desc;
select score(1), text from foo where 
   contains (text, 'fred ACCUM maria', 1) >0 order by score(1) desc;


select score(1), text from foo where
   contains (text, '
<query>
  <textquery>
    fred=maria
  </textquery>
  <score datatype="float" algorithm="count"/>
</query>
', 1) > 0;
