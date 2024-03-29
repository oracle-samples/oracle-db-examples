create table demotable (
  title       varchar2(40), 
  author      varchar2(30), 
  articledate date, 
  text        clob, 
  mediatype   varchar2(20), 
  star_rating varchar2(20)
);

insert into demotable values (
  'A Database Performance Primer', 
  'Fred Smith',
  '20-Jan-2010',
  'Learn to tune your database for maximum performance',
  '1,7',
  '4');

insert into demotable values (
  'Databases for work and leisure', 
  'Fred Jones',
  '17-Feb-2011',
  'How to make money and have fun with a database',
  '1',
  '5');

exec ctx_ddl.create_preference('my_datastore', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('my_datastore', 'COLUMNS', '*')

exec ctx_ddl.create_section_group('my_section_group', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_sdata_section('my_section_group', 'title', 'title')
exec ctx_ddl.add_sdata_section('my_section_group', 'author', 'author')
exec ctx_ddl.add_sdata_section('my_section_group', 'articledate', 'articledate')
exec ctx_ddl.add_mvdata_section('my_section_group', 'mediatype', 'mediatype')
exec ctx_ddl.add_mvdata_section('my_section_group', 'star_rating', 'star_rating')

exec ctx_ddl.create_preference('my_storage', 'basic_storage')
exec ctx_ddl.set_attribute('my_storage', 'BIG_IO', 'true')

CREATE INDEX demotable_index ON demotable (text) 
INDEXTYPE IS ctxsys.context
PARAMETERS ('datastore my_datastore section group my_section_group storage my_storage')
/

variable rsd clob
variable rsout clob

-- avoid prompts from ampersand char
set define off

BEGIN
  :rsd :=
'<ctx_result_set_descriptor>
  <hitlist start_hit_num="1" end_hit_num="10" order="score desc">
    <rowid />
    <sdata name="title" />
    <sdata name="author" />
    <sdata name="articledate" />
    <snippet radius="20" max_length="160" starttag="&lt;b&gt;" endtag="&lt;/b&gt;" />
  </hitlist>
  <count />
  <group mvdata = "mediatype" topn="10">
    <count/>
  </group>
  <group mvdata = "star_rating" topn="10">
    <count/>
  </group>
</ctx_result_set_descriptor>
';
  -- create a temporary LOB for the output
  dbms_lob.createtemporary(:rsout, true);
END;
/

BEGIN 
  ctx_query.result_set(
   index_name            => 'demotable_index',
   query                 => 'database',
   result_set_descriptor => :rsd,
   result_set            => :rsout
  );
END;
/

SELECT XMLTYPE(:rsout) FROM dual;

SELECT mediatype, summary_count FROM 
   XMLTABLE(
    '//groups[@mvdata="MEDIATYPE"]/group'
    PASSING xmltype(:rsout)
    COLUMNS
     mediatype     NUMBER PATH '@value',
     summary_count NUMBER PATH 'count/text()'
  );


