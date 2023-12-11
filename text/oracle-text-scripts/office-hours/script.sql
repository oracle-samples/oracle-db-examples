drop table pangrams;
exec ctx_ddl.drop_preference   ('my_datastore')
exec ctx_ddl.drop_section_group('my_asg')
exec ctx_ddl.drop_section_group('my_hsg')

create table pangrams (text varchar2(50), num_chars number, author varchar2(50));
insert into pangrams values (
  'the quick brown fox jumps over the lazy dog', 35, 'John Peters' );
insert into pangrams values (
  'waltz, bad nymph, for quick jigs flex', 28, 'Johann Smythe' );
insert into pangrams values (
  'the five boxing wizards jump quickly', 31, 'Peter Fox' );

create index pangram_index on pangrams (text)
indextype is ctxsys.context;

select * from pangrams where contains (text, 'quick') > 0;

exec ctx_ddl.create_preference('my_datastore', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('my_datastore', 'COLUMNS', 'text,num_chars,author');

drop index pangram_index;

create index pangram_index on pangrams (text)
indextype is ctxsys.context
parameters ('datastore my_datastore');

select * from pangrams where contains (text, 'quick%') > 0;
select * from pangrams where contains (text, 'quick% AND peter') > 0;

exec ctx_ddl.create_section_group('my_asg', 'AUTO_SECTION_GROUP')

drop index pangram_index;

create index pangram_index on pangrams (text)
indextype is ctxsys.context
parameters ('
  datastore     my_datastore
  section group my_asg
'); 

select * from pangrams where contains (text, 'fox') > 0;
select * from pangrams where contains (text, 'fox WITHIN author') > 0;

exec ctx_ddl.create_section_group('my_hsg', 'HTML_SECTION_GROUP')
exec ctx_ddl.add_ndata_section   ('my_hsg', 'auth',  'author')
exec ctx_ddl.add_sdata_section   ('my_hsg', 'count', 'num_chars', 'NUMBER')

drop index pangram_index;

create index pangram_index on pangrams (text)
indextype is ctxsys.context
parameters ('
  datastore     my_datastore
  section group my_hsg
'); 

select * from pangrams where contains (text, 'NDATA(auth, jo ann smith)') > 0;
select * from pangrams where contains (text, 'SDATA(count < 32)') > 0;


