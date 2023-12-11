drop table my_table
/
create table my_table( text varchar2(2000) )
/
insert into my_table values ('<metadata> dog </metadata><content> cat </content>' )
/
insert into my_table values ('<metadata> cat </metadata><content> dog </content>' )
/

exec ctx_ddl.drop_section_group  ( 'my_sg' )
exec ctx_ddl.create_section_group( 'my_sg', 'BASIC_SECTION_GROUP'  )
exec ctx_ddl.add_field_section   ( 'my_sg', 'metadata', 'metadata' )
exec ctx_ddl.add_field_section   ( 'my_sg', 'content',  'content'  )

create index my_index on my_table( text )
indextype is ctxsys.context
parameters( 'section group my_sg' )
/

select  
   ( case 
     when score(1) > 50 then 'Metadata'
     else 'Content' 
     end  
   ) as SOURCE, 
   text 
from my_table where contains( text, '
<query>
  <textquery>
    <progression>
      <seq> dog WITHIN metadata </seq>
      <seq> dog WITHIN content </seq>
    </progression>
  </textquery>
</query>
',1) > 0;
