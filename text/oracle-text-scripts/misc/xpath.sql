drop table abc;

create table abc(id number, pqr xmltype);

insert into abc values (1, '
<ab:IncidentReportGroup 
xmlns:ab="http://xml.crossflo.com/jxdm/3.0.3" xmlns:j="http://www.it.ojp.gov/jxdm/3.0.3" 
xmlns:ext="http://xml.crossflo.com/jxdm/3.0.3/extension" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.it.ojp.xyz/jxdm/appinfo/1"> 
<ab:IncidentReport>
<ext:DocumentDescriptiveMetadata>
<j:DocumentID>
<j:ID>12345678</j:ID>
</j:DocumentID>
<j:DocumentTypeText>I</j:DocumentTypeText>
<j:DocumentCreationDate>2004-07-14</j:DocumentCreationDate>
<j:DocumentSubmitter.Organization>
<j:OrganizationName>abc</j:OrganizationName>
<j:OrganizationLocalID>
<j:ID>abc</j:ID>
</j:OrganizationLocalID>
</j:DocumentSubmitter.Organization>
<ext:DocumentCreationTime>16:13:03Z</ext:DocumentCreationTime>
</ext:DocumentDescriptiveMetadata>
</ab:IncidentReport>
</ab:IncidentReportGroup>
');

insert into abc values (2, '
<ab:IncidentReportGroup 
xmlns:ab="http://xml.crossflo.com/jxdm/3.0.3" xmlns:j="http://www.it.ojp.gov/jxdm/3.0.3" 
xmlns:ext="http://xml.crossflo.com/jxdm/3.0.3/extension" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.it.ojp.xyz/jxdm/appinfo/1"> 
<ab:IncidentReport>
<ext:DocumentDescriptiveMetadata>
<j:DocumentID>
<j:ID>12345678</j:ID>
</j:DocumentID>
<j:DocumentTypeText>O</j:DocumentTypeText>
<j:DocumentCreationDate>2004-07-14</j:DocumentCreationDate>
<j:DocumentSubmitter.Organization>
<j:OrganizationName>abc</j:OrganizationName>
<j:OrganizationLocalID>
<j:ID>abc</j:ID>
</j:OrganizationLocalID>
</j:DocumentSubmitter.Organization>
<ext:DocumentCreationTime>16:13:03Z</ext:DocumentCreationTime>
</ext:DocumentDescriptiveMetadata>
</ab:IncidentReport>
</ab:IncidentReportGroup>
');


begin
ctx_ddl.drop_section_group('xyz_path_group');
end;
/
begin
ctx_ddl.drop_preference('xyz_word_PREF');
end;
/
begin
ctx_ddl.drop_preference('xyz_lexer_PREF1');
end;
/
begin
ctx_ddl.create_section_group('xyz_path_group','PATH_SECTION_GROUP');
end;
/
begin
ctx_ddl.create_preference('xyz_word_PREF','BASIC_WORDLIST');
ctx_ddl.set_attribute('xyz_word_PREF','SUBSTRING_INDEX','TRUE');
ctx_ddl.set_attribute('xyz_word_PREF','PREFIX_INDEX','YES');
end;
/

begin
ctx_ddl.create_preference('xyz_lexer_pref1','BASIC_LEXER'); 
ctx_ddl.set_attribute('xyz_word_PREF','WILDCARD_MAXTERMS','15000');
end;
/

create index xyz on abc(pqr) indextype is ctxsys.context parameters
('datastore ctxsys.direct_datastore wordlist xyz_word_PREF FILTER ctxsys.null_filter lexer xyz_lexer_pref1 
sync(on commit)SECTION GROUP xyz_path_group MEMORY 500M stoplist ctxsys.empty_stoplist');

select id from abc where contains (pqr, 'O inpath (/ab:IncidentReportGroup/ab:IncidentReport/ext:DocumentDescriptiveMetadata/j:DocumentTypeText)') > 0;
select id from abc where contains (pqr, 'I inpath (/ab:IncidentReportGroup/ab:IncidentReport/ext:DocumentDescriptiveMetadata/j:DocumentTypeText)') > 0;
