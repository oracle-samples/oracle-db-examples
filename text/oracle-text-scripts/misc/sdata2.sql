exec ctx_ddl.drop_section_group   ( 'tst_sec_group')
exec ctx_ddl.create_section_group ( 'tst_sec_group', 'BASIC_SECTION_GROUP')

exec CTX_DDL.ADD_SDATA_SECTION    ( 'tst_sec_group', 'PN_EFFECTIVE_START_DATE', 'PN_EFFECTIVE_START_DATE', 'DATE' )
exec CTX_DDL.ADD_SDATA_SECTION    ( 'tst_sec_group', 'PN_EFFECTIVE_END_DATE',   'PN_EFFECTIVE_END_DATE',   'DATE' )
exec CTX_DDL.ADD_NDATA_SECTION    ( 'tst_sec_group', 'PERSON_FNAME',            'FULL_NAME' )
exec CTX_DDL.ADD_ZONE_SECTION     ( 'tst_sec_group', 'PERSON_NAME_ZONE',        'PERSON_NAME' )

drop table tst_otext;

create table tst_otext(person_xml varchar2(2000));

insert into tst_otext values ('
<xml>
  <PERSON_NAME> 
    <PN_EFFECTIVE_START_DATE>2013-01-01</PN_EFFECTIVE_START_DATE> 
    <PN_EFFECTIVE_END_DATE>4712-12-31</PN_EFFECTIVE_END_DATE> 
    <FIRST_NAME>Shalin</FIRST_NAME> 
    <LAST_NAME>Thomas</LAST_NAME> 
    <FULL_NAME>Shalin Thomas</FULL_NAME> 
    <DISPLAY_NAME>Shalin Thomas</DISPLAY_NAME> 
    <LIST_NAME>Thomas, Shalin</LIST_NAME> 
  </PERSON_NAME>
  <PERSON_NAME> 
    <PN_EFFECTIVE_START_DATE>2003-01-01</PN_EFFECTIVE_START_DATE> 
    <PN_EFFECTIVE_END_DATE>2012-12-31</PN_EFFECTIVE_END_DATE> 
    <NAME_TYPE>US</NAME_TYPE> 
    <FIRST_NAME>Shalin</FIRST_NAME> 
    <LAST_NAME>Pandey</LAST_NAME> 
    <FULL_NAME>Shalin Pandey</FULL_NAME> 
    <DISPLAY_NAME>Shalin Pandey</DISPLAY_NAME> 
    <LIST_NAME>Pandey, Shalin</LIST_NAME> 
  </PERSON_NAME> 
</xml>
');

create index i_tst_otext on tst_otext(person_xml)
indextype is ctxsys.context
parameters ('section group tst_sec_group');

drop table results_temp;
create table results_temp (res xmltype);

insert into results_temp 
SELECT * FROM TST_OTEXT WHERE 
CONTAINS (PERSON_XML,'NDATA(PERSON_FNAME,Thomas) AND SDATA(PN_EFFECTIVE_START_DATE <= "2005-01-01")',1) > 0;



