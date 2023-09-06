-- drop table myxml;

create table myxml (xmlvalue clob);

insert into myxml values ('
<ERecord>
  <WorkOrderOperationInformationVVO>
    <WorkOrderOperationInformationVVORow>
      <WorkOrderId>100</WorkOrderId>
    </WorkOrderOperationInformationVVORow>
  </WorkOrderOperationInformationVVO>
  <OperationTransaction>  
    <OperationName>Op100</OperationName>
    <Item>AS54888</Item>
  </OperationTransaction>
</ERecord>
');

-- exec ctx_ddl.drop_section_group('mysections')
exec ctx_ddl.create_section_group('mysections', 'XML_SECTION_GROUP')

-- true in 4th arg means it's searchable outside the section as well
exec ctx_ddl.add_field_section('mysections', 'Item', 'Item', TRUE)
-- this will be range searchable
exec ctx_ddl.add_sdata_section('mysections', 'WorkOrderId', 'WorkOrdrderId', 'NUMBER')

create index myxmlindex on myxml(xmlvalue)
indextype is ctxsys.context
parameters ('section group mysections sync (on commit)')
/

select * from myxml where contains(xmlvalue, 'AS54888 within Item') > 0;

-- now add a new field section "OtherItem"

alter index myxmlindex rebuild parameters('add field section OtherItem TAG OtherItem VISIBLE');

insert into myxml values ('
<ERecord>
  <WorkOrderOperationInformationVVO>
    <WorkOrderOperationInformationVVORow>
      <WorkOrderId>150</WorkOrderId>
    </WorkOrderOperationInformationVVORow>
  </WorkOrderOperationInformationVVO>
  <OperationTransaction>  
    <OperationName>Op200</OperationName>
    <Item>AS54888</Item>
    <OtherItem>AS54889</OtherItem>
  </OperationTransaction>
</ERecord>
');

commit;

select * from myxml where contains(xmlvalue, 'AS54889 within OtherItem') > 0;
