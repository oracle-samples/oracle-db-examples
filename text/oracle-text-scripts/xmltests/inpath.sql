-- shows how to use path sections and INPATH operator with XML

drop table ip;

create table ip (text varchar2(2000));

insert into ip values ('
<label>
  <labeledEntities>
    <labeledEntity>
      <type>file</type>
      <label>hers</label>
    </labeledEntity>
    <labeledEntity>
      <type>directory</type>
      <label>his</label>
    </labeledEntity>
  </labeledEntities>
</label>
');

insert into ip values ('
<label>
  <labeledEntities>
    <labeledEntity>
      <type>directory</type>
      <label>hers</label>
    </labeledEntity>
    <labeledEntity>
      <type>file</type>
      <label>his</label>
    </labeledEntity>
  </labeledEntities>
</label>
');

exec ctx_ddl.drop_section_group('ipsg')
exec ctx_ddl.create_section_group('ipsg', 'PATH_SECTION_GROUP')

create index idind on ip(text) indextype is ctxsys.context
parameters ('section group ipsg stoplist ctxsys.empty_stoplist');

set feedback 1

select * from ip where contains (text, 
'( (his) INPATH (//label) AND directory INPATH(//type) ) INPATH (/label/labeledEntities/labeledEntity)') > 0;

select * from ip where contains (text, 
'his INPATH (//label/labeledEntities/labeledEntity[type="directory"]/label) ' ) > 0;
