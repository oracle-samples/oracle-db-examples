drop table test;

create table test (text varchar2(2000));

insert into test values ('hello world blah blah blah blah blah blah hello blah world blah blah blah blah blah blah hello blah blah world  blah blah blah blah blah blah hello hello blah blah blah world');

create index textindex on test(text) indextype is ctxsys.context;

select score(1) from test where contains (text, '
<query>
  <textquery>
     near( (hello,world), 5)
  </textquery>
  <score datatype="INTEGER" algorithm="COUNT"/>
</query>
', 1) > 0;
