drop table emp;
create table emp( EMPID number, DEPTNO number,  ENAME varchar2(30), ACTIVE varchar2(1));

insert into emp values (1, 10, 'Scott Weirshire', 'Y');
insert into emp values (2, 20, 'Scully Weiman',   'N');
insert into emp values (3, 30, 'Scott Weiman',    'Y');
insert into emp values (3, 40, 'Scott Weirshire', 'N');

exec ctx_ddl.drop_preference  ('mymcds')
exec ctx_ddl.create_preference('mymcds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('mymcds', 'COLUMNS', 'empid, deptno, regexp_replace(ename, '' .*'', '''') as FIRSTNAME, ename')

exec ctx_ddl.drop_section_group  ('mysec')
exec ctx_ddl.create_section_group('mysec', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_field_section   ('mysec', 'empid', 'empid')
exec ctx_ddl.add_field_section   ('mysec', 'deptno', 'deptno')
exec ctx_ddl.add_field_section   ('mysec', 'firstname', 'firstname')
exec ctx_ddl.add_field_section   ('mysec', 'ename', 'ename')

create index emptextindex on emp(ename) indextype is ctxsys.context
parameters('datastore mymcds section group mysec');

define SEARCH=Scott

select * from emp
where contains (ename, '

&lt;query&gt;
  &lt;textquery&gt;
    &lt;progression&gt;
      &lt;seq&gt;&amp;SEARCH  within empid    &lt;/seq&gt;
      &lt;seq&gt;&amp;SEARCH% within empid    &lt;/seq&gt;
      &lt;seq&gt;&amp;SEARCH  within firstname&lt;/seq&gt;
      &lt;seq&gt;&amp;SEARCH  within ename    &lt;/seq&gt;
      &lt;seq&gt;&amp;SEARCH% within ename    &lt;/seq&gt;
    &lt;/progression&gt;
  &lt;/textquery&gt;
&lt;/query&gt;', 1) &gt; 0 order by active desc, score(1) desc;




