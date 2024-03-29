exec ctx_ddl.drop_preference  ('myds')
exec ctx_ddl.create_preference('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('myds', 'COLUMNS', '''xxstart ''||company||'' xxend''')

drop table foo;

create table foo(company varchar2(50));

insert into foo values ('Oracle Corporation Nigeria');
insert into foo values ('Oracle Corporation');
insert into foo values ('The Other Oracle Corporation somewhere else');


create index fooindex on foo(company) indextype is ctxsys.context
parameters ('datastore myds');


define searchterm='oracle corporation'

-- query demonstrates manipulation of score to identify the buckets, or sequence
-- within progressive relaxation that is hit. 33 works when there are 3 sequences,
-- for 4 it would be 25, for 5 it would be 20, and so on.

select floor( ((100-score(1))+1)/33 ) as "Sequence Hit", company from foo
where contains (company, '
<query>
  <textquery>
    <progression>
      <seq>xxstart &searchterm xxend</seq>
      <seq>xxstart &searchterm</seq>
      <seq>&searchterm</seq>
    </progression>
  </textquery>
</query>', 1) > 0
order by score(1) desc;
