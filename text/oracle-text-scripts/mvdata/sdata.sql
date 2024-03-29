set echo on
set pagesize 65
set linesize 132
set long 50000

drop table demotable;

create table demotable (
  title       varchar2(40), 
  author      varchar2(30), 
  articledate date, 
  text        clob, 
  mediatype   varchar2(50), 
  star_rating varchar2(20)
);

insert into demotable values (
  'A Database Performance Primer', 
  'Fred Smith',
  to_date('2010-01-20', 'YYYY-MM-DD'),
  'Learn to tune your database for maximum performance',
  '<media>dvd</media><media>book</media>',
  '4');

insert into demotable values (
  'Databases for work and leisure', 
  'Fred Jones',
  to_date('2011-02-17', 'YYYY-MM-DD'),
  'How to make money and have fun with a database',
  '<media>book</media>',
  '5');

exec ctx_ddl.drop_preference  ('my_ds')
exec ctx_ddl.create_preference('my_ds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('my_ds', 'COLUMNS', '*')

exec ctx_ddl.drop_section_group    ('my_sg')
exec ctx_ddl.create_section_group  ('my_sg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_sdata_section     ('my_sg', 'title',       'title')
exec ctx_ddl.add_sdata_section     ('my_sg', 'author',      'author')
exec ctx_ddl.add_sdata_section     ('my_sg', 'articledate', 'articledate',   'DATE')
exec ctx_ddl.set_section_attribute ('my_sg', 'articledate', 'optimized_for', 'SEARCH')
exec ctx_ddl.add_sdata_section     ('my_sg', 'media',       'media')
exec ctx_ddl.set_section_attribute ('my_sg', 'media',       'optimized_for', 'SEARCH')
exec ctx_ddl.add_sdata_section     ('my_sg', 'star_rating', 'star_rating',   'NUMBER')
exec ctx_ddl.set_section_attribute ('my_sg', 'star_rating', 'optimized_for', 'SEARCH')

exec ctx_ddl.drop_preference  ('my_storage')
exec ctx_ddl.create_preference('my_storage', 'basic_storage')
exec ctx_ddl.set_attribute    ('my_storage', 'BIG_IO', 'false')

CREATE INDEX demotable_index ON demotable (text) 
INDEXTYPE IS ctxsys.context
PARAMETERS ('datastore my_ds section group my_sg storage my_storage')
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
  <group sdata = "media" bucketby="single" sortby="count">
    <count/>
  </group>
  <group sdata = "star_rating" bucketby="single" sortby="value" order="asc">
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
