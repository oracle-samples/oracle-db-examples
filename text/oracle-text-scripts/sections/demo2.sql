-----------------------------------------------------------
-- here we create a section group with 1000 field sections:
-----------------------------------------------------------

exec ctx_ddl.drop_section_group('mysec')
exec ctx_ddl.create_section_group('mysec', 'BASIC_SECTION_GROUP')

begin
  for i in 1 .. 1000 loop
     execute immediate ('begin ctx_ddl.add_field_section(''mysec'', ''field' || i || ''', ''field' || i || '''); end;');
  end loop;
end;
/

-- Add one SDATA section that can handle range searches

exec ctx_ddl.add_sdata_section('mysec', 'sdata1', 'sdata1', 'NUMBER')

-- Now we create a table and add some simple data

drop table t;

create table t (metadata clob, doc clob);

insert into t values ('
<metadata>
  <field123>value123</field123>
  <field77>value77 abc</field77>
  <sdata1>25</sdata1>
</metadata>',
'This is the main text of the document. In this example the metadata and text are in separate columns
Note that the "metadata" tag above has no actual effect.
');

-- create the index

exec ctx_ddl.drop_preference  ('myds')
exec ctx_ddl.create_preference('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('myds', 'COLUMNS', 'metadata, doc')

create index ti on t(doc) indextype is ctxsys.context parameters ('datastore myds section group mysec sync(on commit)');

-- test query which searches for phrase, field section and sdata range search:

select count(*) from t where contains (doc, 'main text AND value77 within field77 AND SDATA(sdata1 < 30)') > 0;

-- To add a new field section we can add it directly to the existing index thus:

alter index ti rebuild parameters ('add field section field1001 tag field1001');

-- Insert a document with the new field section and test it

insert into t values ('<field1001>foo</field1001>', 'the doc');
commit;

select count(*) from t where contains (doc, 'foo within field1001') > 0;

-- Add a new SDATA section

alter index ti rebuild parameters ('add sdata section sdata2 tag sdata2 datatype number');

insert into t values ('<sdata2>99</sdata2>', 'the doc');
commit;

select count(*) from t where contains (doc, 'sdata(sdata2 between 90 and 100)') > 0;
