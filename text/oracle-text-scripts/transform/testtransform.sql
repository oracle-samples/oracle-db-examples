drop table foo;
create table foo (text varchar2(2000));
insert into foo values ('<level><item1><name1>hello world</name1></item1></level>');
insert into foo values ('<level value="10"><item1><name1>hello world</name1></item1></level>');
insert into foo values ('<level value="10"><item1><name1>hello</name1></item1></level>');
insert into foo values ('<level value="99"><item1><name1>hello world</name1></item1></level>');

exec ctx_ddl.drop_section_group  ('mysecgrp')
exec ctx_ddl.create_section_group('mysecgrp', 'PATH_SECTION_GROUP')

create index fooindex on foo(text) indextype is ctxsys.context parameters ('section group mysecgrp');

@transform.sql

--select mytransform('hello world', '{', '}', '(', ') INPATH (//level[@value="10"]/item1/name1)', 'ACCUM') from dual;

variable TOKENS varchar2(4000)

exec :TOKENS := 'hello world'

column text format a69

SELECT
 score(1), text
FROM foo
WHERE CONTAINS (text, '
<query>    
  <textquery>{hello world}
    <progression>        
      <seq>' || mytransform(:TOKENS, '{', '}', '(', ') INPATH (//level[@value="10"]/item1/name1)', 'ACCUM') || '</seq>
      <seq>' || mytransform(:TOKENS, '{', '}', '(', ') INPATH (//level[@value="99"]/item1/name1)', 'OR') || '</seq>
      <seq>' || mytransform(:TOKENS, '{', '}', '', '', 'AND') || '</seq>
    </progression>   
  </textquery>
</query>'
,1) > 0 order by score(1) desc;

