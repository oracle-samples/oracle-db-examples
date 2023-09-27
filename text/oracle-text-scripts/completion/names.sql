drop table companies;

create table companies (name varchar2(50));

insert into companies values ('XYZ Company Training Inc');
insert into companies values ('Training Corp');
insert into companies values ('Training');
insert into companies values ('Foobar Training Technologies Inc');

exec ctx_ddl.drop_preference   ('myds')
exec ctx_ddl.create_preference ('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute     ('myds', 'COLUMNS', '''XXSTART '' || name || '' XXEND''')

create index coindex on companies(name)
indextype is ctxsys.context
parameters ('datastore myds')
/

select score(1), name from companies where contains (name, '
<query>
  <textquery>
    <progression>
      <seq>XXSTART training XXEND</seq>
      <seq>XXSTART training</seq>
      <seq>training XXEND</seq>
      <seq>training</seq>
    </progression>
  </textquery>
</query>
', 1) > 0
/

