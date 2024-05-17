drop table mytab;

create table mytab(text varchar2(255));

insert into mytab values ('
  <tag1> foo foo foo </tag1>
  <tag2> foo foo     </tag2> 
  <tag3> bar         </tag3>
  <tag4> baz         </tag4>
');

create index mytabindex on mytab (text) indextype is ctxsys.context
parameters ('section group ctxsys.auto_section_group');

select score(1) from mytab where contains(text, '
DEFINEMERGE 
     ( ( ( (DEFINESCORE( foo, OCCURRENCE) WITHIN tag1) *10 ), 
         ( (DEFINESCORE( foo, OCCURRENCE) WITHIN tag2) *7  ),
         ( (DEFINESCORE( foo, OCCURRENCE) WITHIN tag3) *5  ) ), 
       OR, ADD )
NOT (bag within tag4)
',1 ) > 0;
